defmodule Ve do
  alias Ve.Validator

  def validate(data, schema) when is_list(schema) do
    []
    |> validation_messages(data, schema)
    |> case do
      [] -> {:ok, data}
      messages -> {:error, messages}
    end
  end

  def validation_messages(messages, data, schema) do
    type_value = Validator.Generic.get_type(schema)
    error_message = Keyword.get(schema, :err_msg)

    messages
    |> Validator.Generic.validate_type(type_value, data, error_message)
    |> case do
      [] ->
        messages
        |> Validator.Generic.validate(data, schema, error_message)
        |> Validator.Specific.validate(type_value, data, schema, error_message)

      error_message ->
        error_message
    end
  end
end
