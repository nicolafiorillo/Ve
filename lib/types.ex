defmodule Ve.Types do
  @type data :: any()
  @type message :: String.t()
  @type result :: {:ok, data()} | {:error, [message()]}
end
