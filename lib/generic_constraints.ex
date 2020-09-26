defmodule Ve.GenericConstraints do
  @type type ::
          :any
          | :string
          | :integer
          | :atom
          | :map
          | :list
          | :tuple
          | :boolean
          | :function
          | :binary
          | :float
          | :pid
          | :port
          | :reference
  @type opt_nullable :: {:nullable, boolean()}
  @type opt_in :: {:in, [any()]}
  @type opt_fixed :: {:value, any()}
  @type opts :: type() | opt_nullable() | opt_in() | opt_fixed()
  @type schema :: [opts()]

  @spec validate([Ve.Types.message()], Ve.Types.data(), schema(), Ve.Types.message()) :: [Ve.Types.message()]
  def validate(messages, data, schema, error_message) do
    nullable_value = :nullable in schema
    in_value = Keyword.get(schema, :in)
    fixed_value = Keyword.get(schema, :value)

    messages
    |> validate_nullable(nullable_value, data, error_message)
    |> validate_in(in_value, data, error_message)
    |> validate_fixed_value(fixed_value, data, error_message)
  end

  defp validate_nullable(messages, false, nil, error_message),
    do: messages ++ [Ve.Utils.message_or_default(error_message, "cannot_be_nullable")]

  defp validate_nullable(messages, _, _, _error_message), do: messages

  defp validate_in(messages, nil, _, _error_message), do: messages

  defp validate_in(messages, schema, _, _) when not is_list(schema), do: messages ++ ["in_should_be_a_list"]

  defp validate_in(messages, schema, data, error_message) do
    if data in schema do
      messages
    else
      messages ++ [Ve.Utils.message_or_default(error_message, "invalid_possible_value")]
    end
  end

  defp validate_fixed_value(messages, nil, _, _error_message), do: messages

  defp validate_fixed_value(messages, value, data, error_message) do
    case value == data do
      false -> messages ++ [Ve.Utils.message_or_default(error_message, "invalid_fixed_value")]
      _ -> messages
    end
  end
end
