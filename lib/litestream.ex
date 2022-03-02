defmodule Litestream do
  @moduledoc """
  This GenServer module allows you to run [Litestream](https://litestream.io/) via a port in the background
  so that you can easily backup your SQLite database to an object store.
  """

  use GenServer,
    restart: :transient,
    shutdown: 15_000

  require Logger

  alias Litestream.Downloader

  @call_timeout 10_000

  # +--------------------------------------------------------------------+
  # |                 GenServer Public API Functions                     |
  # +--------------------------------------------------------------------+

  @doc """
  The `start_link/1` function is used to start the `Litestream` GenServer. After starting the GenServer, the process
  will download the Litestream binary and start it up to begin database replication. The `Litestream` GenServer
  expects a Keyword list with the following options:

  * `:repo` - The Ecto Repo that manages the SQLite database. REQUIRED
  * `:replica_url` - The URL to which the SQLite database should be backed up. REQUIRED
  * `:access_key_id` - The access key ID to the provided `:replica_url`. REQUIRED
  * `:secret_access_key` - The secret access key to the provided `:replica_url`. REQUIRED
  * `:name` - The name of the GenServer process. By default it is `Litestream`. OPTIONAL
  """
  def start_link(opts) do
    state = %{
      repo: Keyword.fetch!(opts, :repo),
      replica_url: Keyword.fetch!(opts, :replica_url),
      access_key_id: Keyword.fetch!(opts, :access_key_id),
      secret_access_key: Keyword.fetch!(opts, :secret_access_key)
    }

    GenServer.start_link(__MODULE__, state, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  This function will cleanly stop the Litestream process, but the GenServer will still be
  running.
  """
  def stop_lightstream(name \\ __MODULE__) do
    GenServer.call(name, :stop_litestream, @call_timeout)
  end

  @doc """
  This function will start the Litestream process, if it is not currently running. If it is
  already running, then this operation is effectively a no-op.
  """
  def start_lightstream(name \\ __MODULE__) do
    GenServer.call(name, :start_litestream, @call_timeout)
  end

  # +------------------------------------------------------------------+
  # |                 GenServer Callback Functions                     |
  # +------------------------------------------------------------------+

  @impl true
  def init(state) do
    repo_config = state.repo.config()
    otp_app = Keyword.fetch!(repo_config, :otp_app)
    database_file = Keyword.fetch!(repo_config, :database)

    # Make sure that the process traps exits so that we can cleanly shutdown the
    # Litestream replication process
    Process.flag(:trap_exit, true)

    updated_state =
      state
      |> Map.put(:otp_app)
      |> Map.put(:database)

    {:ok, updated_state, {:continue, :download_litestream}}
  end

  @impl true
  def handle_continue(:download_litestream, state) do
  end
end
