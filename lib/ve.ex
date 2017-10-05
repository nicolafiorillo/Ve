defmodule Ve do
  @moduledoc false

  @well_known_types [:is_string, :is_integer, :is_atom, :is_map, :is_list, :is_tuple]

  @doc false
  def validate(data, schema) when is_list(schema) do
    messages = []
    pattern = find_pattern_value(schema)

    messages
      |> validate_nullable(:nullable in schema, data)
      |> validate_as_type(schema, data)
      |> validate_string_pattern(pattern, data)
      |> result(data)
  end

  defp validate_as_type(messages, schema, data) do
    messages_on_types = 
      case schema |> get_type() do
        :is_string  -> validate_data_as_type(data, "string", &Kernel.is_bitstring/1)
        :is_integer -> validate_data_as_type(data, "integer", &Kernel.is_integer/1)
        :is_atom    -> validate_data_as_type(data, "atom", &Kernel.is_atom/1)
        :is_list    -> validate_data_as_type(data, "list", &Kernel.is_list/1)
        :is_map     -> validate_data_as_type(data, "map", &Kernel.is_map/1)
        :is_tuple   -> validate_data_as_type(data, "tuple", &Kernel.is_tuple/1)
        _           -> ["unknown_type"]
      end

    messages ++ messages_on_types
  end

  defp find_pattern_value(schema) do
    Enum.find_value(schema, nil, fn k ->
      case k do
        {:pattern, d} -> d
        _ -> false
      end
    end)
  end

  defp validate_string_pattern(messages, nil, _), do: messages
  defp validate_string_pattern(messages, _, nil), do: messages
  defp validate_string_pattern(messages, pattern, data) do
    with {:ok, r} <- Regex.compile(pattern),
         true      <- Regex.match?(r, data) do messages
      else
        {:error, {msg, _}} -> messages ++ ["invalid_regex_pattern: #{msg}"]
        false              -> messages ++ ["pattern_not_matched"]

    end
  end
  
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
  defp validate_data_as_type(data, name, validation_func), do: if validation_func.(data), do: [], else: ["#{data}_is_not_#{name}"]
end
