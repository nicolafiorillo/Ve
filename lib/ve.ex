defmodule Ve do
  @moduledoc false

  @well_known_types [:string, :integer, :atom, :map, :list, :tuple, :boolean,
                      :function, :binary, :float, :pid, :port, :reference]
  types = ~w[bitstring integer atom map list tuple boolean function binary float pid port reference]

  @doc false
  def validate(data, schema) when is_list(schema) when is_list(schema) do
    []
    |> internal_validate(data, schema)
    |> result(data)
  end

  defp internal_validate(messages, data, schema) do
    pattern_value = find_value(:pattern, schema)
    max_value = find_value(:max, schema)
    min_value = find_value(:min, schema)
    fields_value = find_value(:fields, schema)
    xor_fields_value = find_value(:xor_fields, schema)
    of_value = find_value(:of, schema)
    fixed_value = find_value(:value, schema)
    error_message = find_value(:err_msg, schema)

    messages
      |> validate_nullable(:nullable in schema, data, error_message)
      |> validate_not_empty(:not_empty in schema, data, error_message)
      |> validate_as_type(schema, data, error_message)
      |> validate_string_pattern(pattern_value, data, error_message)
      |> validate_fixed_value(fixed_value, data, error_message)
      |> validate_max(max_value, data, error_message)
      |> validate_min(min_value, data, error_message)
      |> validate_fields(fields_value, data, error_message)
      |> validate_xor_fields(xor_fields_value, data, error_message)
      |> validate_of(of_value, data, error_message)
    end

  defp validate_as_type(messages, schema, data, _error_message) do
    messages_on_types =
      case schema |> get_type() do
        :string    -> validate_data_as_type(data, "string", &Kernel.is_bitstring/1)
        :integer   -> validate_data_as_type(data, "integer", &Kernel.is_integer/1)
        :atom      -> validate_data_as_type(data, "atom", &Kernel.is_atom/1)
        :list      -> validate_data_as_type(data, "list", &Kernel.is_list/1)
        :map       -> validate_data_as_type(data, "map", &Kernel.is_map/1)
        :tuple     -> validate_data_as_type(data, "tuple", &Kernel.is_tuple/1)
        :boolean   -> validate_data_as_type(data, "boolean", &Kernel.is_boolean/1)
        :function  -> validate_data_as_type(data, "function", &Kernel.is_function/1)
        :binary    -> validate_data_as_type(data, "binary", &Kernel.is_binary/1)
        :float     -> validate_data_as_type(data, "float", &Kernel.is_float/1)
        :pid       -> validate_data_as_type(data, "pid", &Kernel.is_pid/1)
        :port      -> validate_data_as_type(data, "port", &Kernel.is_port/1)
        :reference -> validate_data_as_type(data, "reference", &Kernel.is_reference/1)
        _          -> ["unknown_type"]
      end

    messages ++ messages_on_types
  end

  defp find_value(key, schema) do
    Enum.find(schema, nil, fn
      {^key, _} -> true
      _         -> false
    end)
    |> resolve_value
  end

  defp resolve_value(nil), do: nil
  defp resolve_value({_, v}), do: v

  defp validate_min(messages, nil, _, _error_message), do: messages
  defp validate_min(messages, _, nil, _error_message), do: messages
  defp validate_min(messages, min_value, data, _error_message) when is_number(data) and min_value <= data, do: messages
  defp validate_min(messages, min_value, data, _error_message) when is_list(data) and min_value <= length(data), do: messages
  defp validate_min(messages, _, _, nil), do: messages ++ ["min_violation"]
  defp validate_min(messages, _, _, error_message), do: messages ++ [error_message]

  defp validate_max(messages, nil, _, _error_message), do: messages
  defp validate_max(messages, _, nil, _error_message), do: messages
  defp validate_max(messages, max_value, data, _error_message) when is_number(data) and max_value >= data, do: messages
  defp validate_max(messages, max_value, data, _error_message) when is_list(data) and max_value >= length(data), do: messages
  defp validate_max(messages, _, _, nil), do: messages ++ ["max_violation"]
  defp validate_max(messages, _, _, error_message), do: messages ++ [error_message]

  defp validate_string_pattern(messages, nil, _, _error_message), do: messages
  defp validate_string_pattern(messages, _, nil, _error_message), do: messages
  defp validate_string_pattern(messages, pattern, data, error_message) do
    case Regex.match?(pattern, data) do
      false -> messages ++ [message_or_default(error_message, "pattern_not_matched")]
      _     -> messages
    end
  end

  defp message_or_default(nil, def), do: def
  defp message_or_default(msg, _def), do: msg

  defp validate_fixed_value(messages, nil, _, _error_message), do: messages
  defp validate_fixed_value(messages, _, nil, _error_message), do: messages
  defp validate_fixed_value(messages, value, data, error_message) do
    case value == data do
      false -> messages ++ [message_or_default(error_message, "invalid_fixed_value")]
      _     -> messages
    end
  end

  defp validate_fields(messages, nil, _, _error_message), do: messages
  defp validate_fields(messages, _, nil, _error_message), do: messages
  defp validate_fields(messages, fields, data, error_message) do
    Enum.reduce(fields, messages, fn {field, schema}, messages ->
      optional = :optional in schema
      nullable = :nullable in schema
      is_present = Map.has_key?(data, field)

      case {is_present, optional, nullable, Map.get(data, field)} do
        {false, false, _, _}  -> messages ++ [message_or_default(error_message, "missing_field_#{field}")]
        {false, _, _, _}      -> messages
        {true, _, true, nil}  -> messages
        {true, _, false, nil} -> messages ++ [message_or_default(error_message, "field_#{field}_not_nullable")]
        {_, _, _, data}       -> internal_validate(messages, data, schema)
      end
    end)
  end

  defp validate_xor_fields(messages, nil, _, _error_message), do: messages
  defp validate_xor_fields(messages, _, nil, _error_message), do: messages
  defp validate_xor_fields(messages, fields, data, error_message) do
    present_fields = Enum.filter(fields, fn {field, _schema} -> Map.get(data, field) != nil end)
    case length(present_fields) do
      0 -> messages ++ [message_or_default(error_message, "at_lease_one_field_must_be_present")]
      1 -> {field, schema} = List.first(present_fields)
           field_data = Map.get(data, field)
           internal_validate(messages, field_data, schema)
      2 -> messages ++ [message_or_default(error_message, "just_one_field_must_be_present")]
    end
  end

  defp validate_of(messages, nil, _, _error_message), do: messages
  defp validate_of(messages, _, nil, _error_message), do: messages
  defp validate_of(messages, schema, data, _error_message) when is_list(data) do
    Enum.reduce(data, messages, fn field, messages ->
      internal_validate(messages, field, schema)
    end)
  end
  defp validate_of(messages, _, _, nil), do: messages ++ ["of_is_valid_only_in_list"]
  defp validate_of(messages, _, _, error_message), do: messages ++ [error_message]

  defp validate_nullable(messages, false, nil, nil), do: messages ++ ["cannot_be_nullable"]
  defp validate_nullable(messages, false, nil, error_message), do: messages ++ [error_message]
  defp validate_nullable(messages, _, _, _error_message), do: messages

  defp validate_not_empty(messages, true, data, error_message), do: messages |> validate_not_empty_string(data |> String.trim(), error_message)
  defp validate_not_empty(messages, _, _, _error_message), do: messages

  defp validate_not_empty_string(messages, "", nil), do: messages ++ ["string_cannot_be_empty"]
  defp validate_not_empty_string(messages, "", error_message), do: messages ++ [error_message]
  defp validate_not_empty_string(messages, _, _error_message), do: messages

  defp result([], data), do: {:ok, data}
  defp result(messages, _), do: {:error, messages}

  defp get_type(schema) when is_list(schema) do
    schema |> Enum.reduce(nil, fn f, acc -> f in @well_known_types |> choose_type(f, acc) end)
  end

  defp choose_type(true, val, _), do: val
  defp choose_type(false, _, val), do: val

  defp validate_data_as_type(nil, _, _), do: []
  defp validate_data_as_type(data, name, validation_func), do: if validation_func.(data), do: [], else: ["#{name}_expected_got_#{typeof(data)}"]

  for type <- types do
    def typeof(x) when unquote(:"is_#{type}")(x), do: unquote(type)
  end
end
