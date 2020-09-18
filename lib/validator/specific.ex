defmodule Ve.Validator.Specific do
  alias Ve.Utils

  def validate(messages, _type, nil, _schema, _error_message) do
    messages
  end

  def validate(messages, :string, data, schema, error_message) do
    not_empty_value = :not_empty in schema
    pattern_value = Keyword.get(schema, :pattern)

    messages
    |> validate_not_empty(not_empty_value, data, error_message)
    |> validate_string_pattern(pattern_value, data, error_message)
  end

  def validate(messages, type, data, schema, error_message)
      when type == :integer or type == :float do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
  end

  def validate(messages, :map, data, schema, error_message) do
    fields_value = Keyword.get(schema, :fields)
    xor_value = Keyword.get(schema, :xor)

    messages
    |> validate_fields(fields_value, data, error_message)
    |> validate_xor(xor_value, data, error_message)
  end

  def validate(messages, :list, data, schema, error_message) do
    min_value = Keyword.get(schema, :min)
    max_value = Keyword.get(schema, :max)
    of_value = Keyword.get(schema, :of)

    messages
    |> validate_min(min_value, data, error_message)
    |> validate_max(max_value, data, error_message)
    |> validate_of(of_value, data, error_message)
  end

  def validate(messages, _type, _data, _schema, _error_message) do
    messages
  end

  defp validate_min(messages, nil, _, _error_message), do: messages

  defp validate_min(messages, min_value, data, _error_message) when is_number(data) and min_value <= data, do: messages

  defp validate_min(messages, min_value, data, _error_message) when is_list(data) and min_value <= length(data),
    do: messages

  defp validate_min(messages, _, _, error_message),
    do: messages ++ [Utils.message_or_default(error_message, "min_violation")]

  defp validate_max(messages, nil, _, _error_message), do: messages

  defp validate_max(messages, max_value, data, _error_message) when is_number(data) and max_value >= data, do: messages

  defp validate_max(messages, max_value, data, _error_message) when is_list(data) and max_value >= length(data),
    do: messages

  defp validate_max(messages, _, _, error_message),
    do: messages ++ [Utils.message_or_default(error_message, "max_violation")]

  defp validate_string_pattern(messages, nil, _, _error_message), do: messages

  defp validate_string_pattern(messages, pattern, data, error_message) do
    case Regex.match?(pattern, data) do
      false -> messages ++ [Utils.message_or_default(error_message, "pattern_not_matched")]
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
        {false, false, _, _} -> messages ++ [Utils.message_or_default(error_message, "missing_field_#{field}")]
        {false, true, _, _} -> messages
        {true, _, false, nil} -> messages ++ [Utils.message_or_default(error_message, "field_#{field}_not_nullable")]
        {true, _, true, nil} -> messages
        _ -> Ve.validation_messages(messages, field_value, schema)
      end
    end)
  end

  defp validate_xor(messages, nil, _, _error_message), do: messages

  defp validate_xor(messages, fields, data, error_message) do
    present_fields = Enum.filter(fields, fn {field, _schema} -> Map.get(data, field) != nil end)

    case length(present_fields) do
      0 ->
        messages ++ [Utils.message_or_default(error_message, "at_lease_one_field_must_be_present")]

      1 ->
        {field, schema} = List.first(present_fields)
        field_data = Map.get(data, field)
        Ve.validation_messages(messages, field_data, schema)

      2 ->
        messages ++ [Utils.message_or_default(error_message, "just_one_field_must_be_present")]
    end
  end

  defp validate_of(messages, nil, _, _error_message), do: messages

  defp validate_of(messages, _, data, error_message) when not is_list(data),
    do: messages ++ [Utils.message_or_default(error_message, "of_is_valid_only_in_list")]

  defp validate_of(messages, schema, data, _error_message) do
    Enum.reduce(data, messages, fn field, messages ->
      Ve.validation_messages(messages, field, schema)
    end)
  end

  defp validate_not_empty(messages, true, data, error_message),
    do: messages |> validate_not_empty_string(data |> String.trim(), error_message)

  defp validate_not_empty(messages, _, _, _error_message), do: messages

  defp validate_not_empty_string(messages, "", error_message),
    do: messages ++ [Utils.message_or_default(error_message, "string_cannot_be_empty")]

  defp validate_not_empty_string(messages, _, _error_message), do: messages
end
