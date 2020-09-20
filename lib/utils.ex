defmodule Ve.Utils do
  @spec typeof(any()) :: String.t()
  def typeof(x) when is_bitstring(x), do: "bitstring"
  def typeof(x) when is_integer(x), do: "integer"
  def typeof(x) when is_atom(x), do: "atom"
  def typeof(x) when is_map(x), do: "map"
  def typeof(x) when is_list(x), do: "list"
  def typeof(x) when is_tuple(x), do: "tuple"
  def typeof(x) when is_function(x), do: "function"
  def typeof(x) when is_binary(x), do: "binary"
  def typeof(x) when is_float(x), do: "float"
  def typeof(x) when is_pid(x), do: "pid"
  def typeof(x) when is_port(x), do: "port"
  def typeof(x) when is_reference(x), do: "reference"

  @spec is_any(any()) :: true
  def is_any(_), do: true

  @spec message_or_default(Ve.message() | nil, Ve.message()) :: Ve.message()
  def message_or_default(msg, default), do: msg || default
end
