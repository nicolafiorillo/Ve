defmodule Ve.Utils do
  types = ~w[bitstring integer atom map list tuple boolean function binary float pid port reference]

  for type <- types do
    def typeof(x) when unquote(:"is_#{type}")(x), do: unquote(type)
  end

  def is_any(_), do: true

  def message_or_default(msg, default), do: msg || default
end
