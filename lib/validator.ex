defmodule Ve.Validator do
  @type opts_string :: :not_empty | {:pattern, Regex.t()}
  @type opts_number :: {:min, number()} | {:max, number()}
  @type opts_fields :: :optional | :nullable | Ve.schema()
  @type opts_map :: {:fields, [{Map.key(), opts_fields()}]} | {:xor, [{Map.key(), Ve.schema()}]}
  @type opts_list :: {:min, number()} | {:max, number()} | {:of, Ve.schema()}
  @type opts_tuple :: {:items, [Ve.schema()]}
  @type opts :: opts_number() | opts_string() | opts_map() | opts_list() | opts_tuple()
  @type schema :: [Ve.GenericConstraints.type() | opts()]

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
    reference: &is_reference/1,
    choice: &Ve.Utils.is_choice/1
  }

  @spec validation_messages(Ve.Types.data(), Ve.schema(), [Ve.Types.message()]) :: [Ve.Types.message()]
  def validation_messages(data, schema, messages) do
    type = get_type(schema)
    error_message = Keyword.get(schema, :err_msg)

    validate_type(type, data)
    |> case do
      [] ->
        messages
        |> Ve.GenericConstraints.validate(data, schema, error_message)
        |> validate(type, data, schema, error_message)

      type_error_message ->
        type_error_message ++ messages
    end
  end

  defp validate(messages, _type, nil, _schema, _error_message), do: messages

  defp validate(messages, :string, data, schema, error_message) do
    not_empty_value = :not_empty in schema
    pattern_value = Keyword.get(schema, :pattern)

    messages
    |> validate_not_empty(not_empty_value, data, error_message)
    |> validate_string_pattern(pattern_value, data, error_message)
  end

  defp validate(messages, type, data, schema, error_message)
       when type == :integer or type == :float do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
  end

  defp validate(messages, :map, data, schema, error_message) do
    fields_value = Keyword.get(schema, :fields)
    xor_value = Keyword.get(schema, :xor)

    messages
    |> validate_fields(fields_value, data, error_message)
    |> validate_xor(xor_value, data, error_message)
  end

  defp validate(messages, :list, data, schema, error_message) do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)
    of_value = Keyword.get(schema, :of)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
    |> validate_list_of(of_value, data, error_message)
  end

  defp validate(messages, :tuple, data, schema, error_message) do
    of_value = Keyword.get(schema, :of)

    messages
    |> validate_tuple_of(of_value, data, error_message)
  end

  defp validate(messages, :choice, data, schema, error_message) do
    of_value = Keyword.get(schema, :of, )

    messages
    |> validate_choice_of(of_value, data, error_message)
  end

  defp validate(messages, _type, _data, _schema, _error_message) do
    messages
  end

  defp validate_tuple_of(messages, nil, _, _error_message), do: messages

  defp validate_tuple_of(messages, items, data, error_message) when tuple_size(data) != length(items),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "tuple_size_is_not_#{length(items)}")]

  defp validate_tuple_of(messages, items, data, _error_message) do
    data = data |> Tuple.to_list()

    Enum.reduce(Enum.zip(items, data), messages, fn {schema, field}, messages ->
      validation_messages(field, schema, messages)
    end)
  end

  defp validate_choice_of(messages, nil, _, _error_message), do: messages

  defp validate_choice_of(messages, choices, data, error_message) do
    is_valid =
      Enum.any?(
        choices,
        fn schema ->
          validation_messages(data, schema, messages) == []
        end
      )

    if is_valid do
      messages
    else
      messages ++ [Ve.Utils.message_or_default(error_message, "invalid_choice")]
    end
  end

  defp validate_type(type, data) do
    is_type_fun = Map.get(@type_2_is_type_fun, type)

    cond do
      data == nil -> []
      type == nil -> ["unknown_type"]
      is_type_fun.(data) -> []
      true -> ["#{type}_expected_got_#{Ve.Utils.typeof(data)}"]
    end
  end

  defp validate_min(messages, nil, _, _error_message), do: messages

  defp validate_min(messages, min_value, data, _error_message) when is_number(data) and min_value <= data, do: messages

  defp validate_min(messages, min_value, data, _error_message) when is_list(data) and min_value <= length(data),
    do: messages

  defp validate_min(messages, _, _, error_message),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "min_violation")]

  defp validate_max(messages, nil, _, _error_message), do: messages

  defp validate_max(messages, max_value, data, _error_message) when is_number(data) and max_value >= data, do: messages

  defp validate_max(messages, max_value, data, _error_message) when is_list(data) and max_value >= length(data),
    do: messages

  defp validate_max(messages, _, _, error_message),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "max_violation")]

  defp validate_string_pattern(messages, nil, _, _error_message), do: messages

  defp validate_string_pattern(messages, pattern, data, error_message) do
    case Regex.match?(pattern, data) do
      false -> messages ++ [Ve.Utils.message_or_default(error_message, "pattern_not_matched")]
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
        {false, false, _, _} -> messages ++ [Ve.Utils.message_or_default(error_message, "missing_field_#{field}")]
        {false, true, _, _} -> messages
        {true, _, false, nil} -> messages ++ [Ve.Utils.message_or_default(error_message, "field_#{field}_not_nullable")]
        {true, _, true, nil} -> messages
        _ -> validation_messages(field_value, schema, messages)
      end
    end)
  end

  defp validate_xor(messages, nil, _, _error_message), do: messages

  defp validate_xor(messages, fields, data, error_message) do
    present_fields = Enum.filter(fields, fn {field, _schema} -> Map.get(data, field) != nil end)

    case length(present_fields) do
      0 ->
        messages ++ [Ve.Utils.message_or_default(error_message, "at_lease_one_field_must_be_present")]

      1 ->
        {field, schema} = List.first(present_fields)
        field_data = Map.get(data, field)
        validation_messages(field_data, schema, messages)

      2 ->
        messages ++ [Ve.Utils.message_or_default(error_message, "just_one_field_must_be_present")]
    end
  end

  defp validate_list_of(messages, nil, _, _error_message), do: messages

  defp validate_list_of(messages, schema, _data, error_message) when not is_list(schema),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "of_is_valid_only_in_list")]

  defp validate_list_of(messages, schema, data, _error_message) do
    Enum.reduce(data, messages, fn field, messages ->
      validation_messages(field, schema, messages)
    end)
  end

  defp validate_not_empty(messages, true, data, error_message),
    do: messages |> validate_not_empty_string(data |> String.trim(), error_message)

  defp validate_not_empty(messages, _, _, _error_message), do: messages

  defp validate_not_empty_string(messages, "", error_message),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "string_cannot_be_empty")]

  defp validate_not_empty_string(messages, _, _error_message), do: messages

  defp get_type(schema) do
    if :choice in schema do
      :choice
    else
      Enum.find(schema, &Map.has_key?(@type_2_is_type_fun, &1))
    end
  end
end
