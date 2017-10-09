defmodule Ve do
  @moduledoc false

  @well_known_types [:is_string, :is_integer, :is_atom, :is_map, :is_list, :is_tuple, :is_boolean,
                      :is_function, :is_binary, :is_float, :is_pid, :is_port, :is_reference]
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
    
    messages
      |> validate_nullable(:nullable in schema, data)
      |> validate_as_type(schema, data)
      |> validate_string_pattern(pattern_value, data)
      |> validate_integer_max(max_value, data)
      |> validate_integer_min(min_value, data)
      |> validate_fields(fields_value, data)
      |> validate_xor_fields(xor_fields_value, data)
      |> validate_of(of_value, data)
    end

  defp validate_as_type(messages, schema, data) do
    messages_on_types = 
      case schema |> get_type() do
        :is_string    -> validate_data_as_type(data, "string", &Kernel.is_bitstring/1)
        :is_integer   -> validate_data_as_type(data, "integer", &Kernel.is_integer/1)
        :is_atom      -> validate_data_as_type(data, "atom", &Kernel.is_atom/1)
        :is_list      -> validate_data_as_type(data, "list", &Kernel.is_list/1)
        :is_map       -> validate_data_as_type(data, "map", &Kernel.is_map/1)
        :is_tuple     -> validate_data_as_type(data, "tuple", &Kernel.is_tuple/1)
        :is_boolean   -> validate_data_as_type(data, "boolean", &Kernel.is_boolean/1)
        :is_function  -> validate_data_as_type(data, "function", &Kernel.is_function/1)
        :is_binary    -> validate_data_as_type(data, "binary", &Kernel.is_binary/1)
        :is_float     -> validate_data_as_type(data, "float", &Kernel.is_float/1)
        :is_pid       -> validate_data_as_type(data, "pid", &Kernel.is_pid/1)
        :is_port      -> validate_data_as_type(data, "port", &Kernel.is_port/1)
        :is_reference -> validate_data_as_type(data, "reference", &Kernel.is_reference/1)
        _           -> ["unknown_type"]
      end

    messages ++ messages_on_types
  end

  defp find_value(key, schema) do
    Enum.find_value(schema, nil, fn k ->
      case k do
        {^key, d} -> d
        _ -> false
      end
    end)
  end

  defp validate_integer_min(messages, nil, _), do: messages
  defp validate_integer_min(messages, _, nil), do: messages
  defp validate_integer_min(messages, min_value, data) when min_value <= data, do: messages
  defp validate_integer_min(messages, _, _), do: messages ++ ["min_violation"]
  
  defp validate_integer_max(messages, nil, _), do: messages
  defp validate_integer_max(messages, _, nil), do: messages
  defp validate_integer_max(messages, max_value, data) when max_value >= data, do: messages
  defp validate_integer_max(messages, _, _), do: messages ++ ["max_violation"]

  defp validate_string_pattern(messages, nil, _), do: messages
  defp validate_string_pattern(messages, _, nil), do: messages
  defp validate_string_pattern(messages, pattern, data) do
    case Regex.match?(pattern, data) do
      false -> messages ++ ["pattern_not_matched"]
      _     -> messages
    end
  end
  
  defp validate_fields(messages, nil, _), do: messages
  defp validate_fields(messages, _, nil), do: messages
  defp validate_fields(messages, fields, data) do
    Enum.reduce(fields, messages, fn {field, schema}, messages ->
      optional = :optional in schema
      
      case {Map.get(data, field), optional} do
        {nil, false} -> messages ++ ["missing_field_#{field}"]
        {nil, _}     -> messages
        {data, _}    -> internal_validate(messages, data, schema)
      end
    end)
  end

  defp validate_xor_fields(messages, nil, _), do: messages
  defp validate_xor_fields(messages, _, nil), do: messages
  defp validate_xor_fields(messages, fields, data) do
    present_fields = Enum.filter(fields, fn {field, _schema} -> Map.get(data, field) != nil end)
    case length(present_fields) do
      0 -> messages ++ ["at_lease_one_field_must_be_present"]
      1 -> {field, schema} = List.first(present_fields)
           field_data = Map.get(data, field)
           internal_validate(messages, field_data, schema)
      2 -> messages ++ ["just_one_field_must_be_present"]
    end
  end

  defp validate_of(messages, nil, _), do: messages
  defp validate_of(messages, _, nil), do: messages
  defp validate_of(messages, schema, data) when is_list(data) do
    Enum.reduce(data, messages, fn field, messages ->
      internal_validate(messages, field, schema)
    end)
  end
  defp validate_of(messages, _, _), do: messages ++ ["of_is_valid_only_in_list"]
    
  defp validate_nullable(messages, false, nil), do: messages ++ ["cannot_be_nullable"]
  defp validate_nullable(messages, _, _), do: messages
    
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
