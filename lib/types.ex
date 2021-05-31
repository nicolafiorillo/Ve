defmodule Ve.Types do
  @moduledoc false

  @type data :: any()
  @type message :: String.t()
  @type result :: {:ok, data()} | {:error, [message()]}
end
