defmodule Ve do
  @moduledoc false

  @well_known_types [:is_string, :is_integer, :is_atom, :is_map, :is_list, :is_tuple]

  @doc false
  def validate(data, schema) when is_list(schema) do
    case schema |> get_type() do
      :is_string  -> [] |> validate_as_string(data)
      :is_integer -> [] |> validate_as_integer(data)
      :is_atom    -> [] |> validate_as_atom(data)
      :is_list    -> [] |> validate_as_list(data)
      :is_map     -> [] |> validate_as_map(data)
      :is_tuple   -> [] |> validate_as_tuple(data)
      _           -> ["unknown_type"]
    end
    |> result(data)
  end

  defp result([], data), do: {:ok, data}
  defp result(messages, _), do: {:error, messages}

  defp get_type(schema) when is_list(schema) do
    schema |> Enum.reduce(nil, fn f, acc -> f in @well_known_types |> choose_type(f, acc) end)
  end

  defp choose_type(true, val, _), do: val
  defp choose_type(false, _, val), do: val

  defp validate_as_string(messages, data) when is_bitstring(data), do: messages
  defp validate_as_string(messages, data), do: messages ++ ["#{data}_is_not_string"]

  defp validate_as_integer(messages, data) when is_integer(data), do: messages
  defp validate_as_integer(messages, data), do: messages ++ ["#{data}_is_not_integer"]

  defp validate_as_atom(messages, data) when is_atom(data), do: messages
  defp validate_as_atom(messages, data), do: messages ++ ["#{data}_is_not_atom"]

  defp validate_as_list(messages, data) when is_list(data), do: messages
  defp validate_as_list(messages, data), do: messages ++ ["#{data}_is_not_list"]

  defp validate_as_map(messages, data) when is_map(data), do: messages
  defp validate_as_map(messages, data), do: messages ++ ["#{data}_is_not_map"]

  defp validate_as_tuple(messages, data) when is_tuple(data), do: messages
  defp validate_as_tuple(messages, data), do: messages ++ ["#{data}_is_not_tuple"]
end
