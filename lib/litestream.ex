defmodule Litestream do
  @moduledoc """
  This GenServer module allows you to run [Litestream](https://litestream.io/) via a port in the background
  so that you can easily backup your SQLite database to an object store.
  """

  use GenServer

  def start_link(opts) do
  end

  @impl true
  def init(opts) do
  end
end
