defmodule Ve.Validator.Generic do
  alias Ve.Utils

  @type_2_is_type_fun %{
    any: &Utils.is_any/1,
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

  def validate(messages, data, schema, error_message) do
    nullable_value = :nullable in schema
    in_value = Keyword.get(schema, :in)
    fixed_value = Keyword.get(schema, :value)

    messages
    |> validate_nullable(nullable_value, data, error_message)
    |> validate_in(in_value, data, error_message)
    |> validate_fixed_value(fixed_value, data, error_message)
  end

  def validate_type(messages, type, data, _error_message) do
    is_type_fun = Map.get(@type_2_is_type_fun, type)

    extra_messages =
      cond do
        data == nil -> []
        type == nil -> ["unknown_type"]
        is_type_fun.(data) -> []
        true -> ["#{type}_expected_got_#{Utils.typeof(data)}"]
      end

    messages ++ extra_messages
  end

  def get_type(schema), do: Enum.find(schema, &Map.has_key?(@type_2_is_type_fun, &1))

  defp validate_nullable(messages, false, nil, error_message),
    do: messages ++ [Utils.message_or_default(error_message, "cannot_be_nullable")]

  defp validate_nullable(messages, _, _, _error_message), do: messages

  defp validate_in(messages, nil, _, _error_message), do: messages
  defp validate_in(messages, schema, _, _) when not is_list(schema), do: messages ++ ["in_should_be_a_list"]

  defp validate_in(messages, schema, data, error_message) do
    if data in schema do
      messages
    else
      messages ++ [Utils.message_or_default(error_message, "invalid_possible_value")]
    end
  end

  defp validate_fixed_value(messages, nil, _, _error_message), do: messages

  defp validate_fixed_value(messages, value, data, error_message) do
    case value == data do
      false -> messages ++ [Utils.message_or_default(error_message, "invalid_fixed_value")]
      _ -> messages
    end
  end
end
