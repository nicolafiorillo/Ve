defmodule Ve do
  alias Ve.Validator

  @type data :: any()
  @type message :: String.t()
  @type schema :: [Ve.Validator.Generic.opts() | Ve.Validator.Specific.opts()]
  @type result :: {:ok, data()} | {:error, [message()]}

  @spec validate(data(), schema()) :: result()
  def validate(data, schema) do
    []
    |> validation_messages(data, schema)
    |> on_error()
    |> on_ok(data)
  end

  @spec validation_messages([message()], data(), schema()) :: [message()]
  def validation_messages(messages, data, schema) do
    type = Validator.Generic.get_type(schema)
    error_message = Keyword.get(schema, :err_msg)

    Validator.Generic.validate_type(type, data)
    |> case do
      [] ->
        messages
        |> Validator.Generic.validate(data, schema, error_message)
        |> Validator.Specific.validate(type, data, schema, error_message)

      type_error_message ->
        type_error_message ++ messages
    end
  end

  defp on_error([]), do: :ok
  defp on_error(messages), do: {:error, messages}

  defp on_ok(:ok, data), do: {:ok, data}
  defp on_ok({:error, _} = res, _data), do: res
end
