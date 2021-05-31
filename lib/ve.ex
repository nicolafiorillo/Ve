defmodule Ve do
  @moduledoc false

  @type schema :: [Ve.Validator.opts()]
  @type result :: {:ok, Ve.Types.data()} | {:error, [Ve.Types.message()]}

  @spec validate(Ve.Types.data(), schema()) :: result()
  def validate(data, schema) do
    Ve.Validator.validation_messages(data, schema, [])
    |> on_error()
    |> on_ok(data)
  end

  defp on_error([]), do: :ok
  defp on_error(messages), do: {:error, messages}

  defp on_ok(:ok, data), do: {:ok, data}
  defp on_ok({:error, _} = res, _data), do: res
end
