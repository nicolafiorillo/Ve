defmodule Ve do
  @moduledoc false

  @type_2_is_type_fun %{
    any: &Ve.Utils.is_any/1,
    string: &is_binary/1,
    integer: &is_integer/1,
    atom: &is_atom/1,
    map: &is_map/1,
    list: &is_list/1,
    tuple: &is_tuple/1,
    boolean: &is_boolean/1,
    function: &is_function/1,
    binary: &is_binary/1,
    float: &is_float/1,
    pid: &is_pid/1,
    port: &is_port/1,
    reference: &is_reference/1
  }

  @doc false
  def validate(data, schema) when is_list(schema) do
    []
    |> internal_validate(data, schema)
    |> result(data)
  end

  defp internal_validate(messages, data, schema) do
    type_value = get_type(schema)
    error_message = Keyword.get(schema, :err_msg)

    messages
    |> validate_type(type_value, data, error_message)
    |> case do
      [] ->
        messages
        |> validate_any_type_constraints(data, schema, error_message)
        |> validate_specific_type_constraints(type_value, data, schema, error_message)
      error_message ->
        error_message
    end
  end

  defp validate_any_type_constraints(messages, data, schema, error_message) do
    nullable_value = :nullable in schema
    in_value = Keyword.get(schema, :in)
    fixed_value = Keyword.get(schema, :value)

    messages
    |> validate_nullable(nullable_value, data, error_message)
    |> validate_in(in_value, data, error_message)
    |> validate_fixed_value(fixed_value, data, error_message)
  end

  defp validate_specific_type_constraints(messages, _type, nil, _schema, _error_message) do
    messages
  end

  defp validate_specific_type_constraints(messages, :string, data, schema, error_message) do
    not_empty_value = :not_empty in schema
    pattern_value = Keyword.get(schema, :pattern)

    messages
    |> validate_not_empty(not_empty_value, data, error_message)
    |> validate_string_pattern(pattern_value, data, error_message)
  end

  defp validate_specific_type_constraints(messages, type, data, schema, error_message) when type == :integer or type == :float do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
  end

  defp validate_specific_type_constraints(messages, :map, data, schema, error_message) do
    fields_value = Keyword.get(schema, :fields)
    xor_value = Keyword.get(schema, :xor)

    messages
    |> validate_fields(fields_value, data, error_message)
    |> validate_xor(xor_value, data, error_message)
  end

  defp validate_specific_type_constraints(messages, :list, data, schema, error_message) do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)
    of_value = Keyword.get(schema, :of)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
    |> validate_of(of_value, data, error_message)
  end

  defp validate_specific_type_constraints(messages, _type, _data, _schema, _error_message) do
    messages
  end

  defp validate_type(messages, type, data, _error_message) do
    is_type_fun = Map.get(@type_2_is_type_fun, type)
    messages ++ validate_data_type(data, type, is_type_fun)
  end

  defp validate_min(messages, nil, _, _error_message), do: messages
  defp validate_min(messages, min_value, data, _error_message) when is_number(data) and min_value <= data, do: messages

  defp validate_min(messages, min_value, data, _error_message) when is_list(data) and min_value <= length(data),
    do: messages

  defp validate_min(messages, _, _, error_message), do: messages ++ [message_or_default(error_message, "min_violation")]

  defp validate_max(messages, nil, _, _error_message), do: messages
  defp validate_max(messages, max_value, data, _error_message) when is_number(data) and max_value >= data, do: messages

  defp validate_max(messages, max_value, data, _error_message) when is_list(data) and max_value >= length(data),
    do: messages

  defp validate_max(messages, _, _, error_message), do: messages ++ [message_or_default(error_message, "max_violation")]

  defp validate_string_pattern(messages, nil, _, _error_message), do: messages

  defp validate_string_pattern(messages, pattern, data, error_message) do
    case Regex.match?(pattern, data) do
      false -> messages ++ [message_or_default(error_message, "pattern_not_matched")]
      _ -> messages
    end
  end

  defp message_or_default(msg, default), do: msg || default

  defp validate_fixed_value(messages, nil, _, _error_message), do: messages

  defp validate_fixed_value(messages, value, data, error_message) do
    case value == data do
      false -> messages ++ [message_or_default(error_message, "invalid_fixed_value")]
      _ -> messages
    end
  end

  defp validate_fields(messages, nil, _, _error_message), do: messages

  defp validate_fields(messages, fields, data, error_message) do
    Enum.reduce(fields, messages, fn {field, schema}, messages ->
      optional = :optional in schema
      nullable = :nullable in schema
      is_present = Map.has_key?(data, field)
      field_value = Map.get(data, field)

      case {is_present, optional, nullable, field_value} do
        {false, false, _, _} -> messages ++ [message_or_default(error_message, "missing_field_#{field}")]
        {false, true, _, _} -> messages
        {true, _, false, nil} -> messages ++ [message_or_default(error_message, "field_#{field}_not_nullable")]
        {true, _, true, nil} -> messages
        {_, _, _, data} -> internal_validate(messages, data, schema)
      end
    end)
  end

  defp validate_xor(messages, nil, _, _error_message), do: messages

  defp validate_xor(messages, fields, data, error_message) do
    present_fields = Enum.filter(fields, fn {field, _schema} -> Map.get(data, field) != nil end)

    case length(present_fields) do
      0 ->
        messages ++ [message_or_default(error_message, "at_lease_one_field_must_be_present")]

      1 ->
        {field, schema} = List.first(present_fields)
        field_data = Map.get(data, field)
        internal_validate(messages, field_data, schema)

      2 ->
        messages ++ [message_or_default(error_message, "just_one_field_must_be_present")]
    end
  end

  defp validate_in(messages, nil, _, _error_message), do: messages
  defp validate_in(messages, schema, _, _) when not is_list(schema), do: messages ++ ["in_should_be_a_list"]

  defp validate_in(messages, schema, data, error_message) do
    if data in schema do
      messages
    else
      messages ++ [message_or_default(error_message, "invalid_possible_value")]
    end
  end

  defp validate_of(messages, nil, _, _error_message), do: messages
  defp validate_of(messages, _, data, error_message) when not is_list(data), do: messages ++ [message_or_default(error_message, "of_is_valid_only_in_list")]

  defp validate_of(messages, schema, data, _error_message) do
    Enum.reduce(data, messages, fn field, messages ->
      internal_validate(messages, field, schema)
    end)
  end

  defp validate_nullable(messages, false, nil, error_message), do: messages ++ [message_or_default(error_message, "cannot_be_nullable")]
  defp validate_nullable(messages, _, _, _error_message), do: messages

  defp validate_not_empty(messages, true, data, error_message),
    do: messages |> validate_not_empty_string(data |> String.trim(), error_message)

  defp validate_not_empty(messages, _, _, _error_message), do: messages

  defp validate_not_empty_string(messages, "", error_message), do: messages ++ [message_or_default(error_message, "string_cannot_be_empty")]
  defp validate_not_empty_string(messages, _, _error_message), do: messages

  defp result([], data), do: {:ok, data}
  defp result(messages, _), do: {:error, messages}

  defp get_type(schema), do: Enum.find(schema, &(Map.has_key?(@type_2_is_type_fun, &1)))

  defp validate_data_type(nil, _, _), do: []
  defp validate_data_type(_, nil, _), do: ["unknown_type"]

  defp validate_data_type(data, type, is_type_fun) do
    if is_type_fun.(data) do
      []
    else
      ["#{type}_expected_got_#{Ve.Utils.typeof(data)}"]
    end
  end
end

defmodule Ve.Utils do
  types = ~w[bitstring integer atom map list tuple boolean function binary float pid port reference]

  for type <- types do
    def typeof(x) when unquote(:"is_#{type}")(x), do: unquote(type)
  end

  def is_any(_), do: true
end
