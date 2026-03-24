defmodule Litestream do
  @moduledoc """
  This GenServer module allows you to run [Litestream](https://litestream.io/) via a port in the background
  so that you can easily backup your SQLite database to an object store, a seperate local file, SFTP, etc.
  """

  use GenServer,
    restart: :transient,
    shutdown: 15_000

  require Logger

  alias Litestream.Downloader
  alias Litestream.Replicator

  @call_timeout 10_000

  # +--------------------------------------------------------------------+
  # |                 GenServer Public API Functions                     |
  # +--------------------------------------------------------------------+

  @doc """
  The `start_link/1` function is used to start the `Litestream` GenServer. After starting the GenServer, the process
  will download the Litestream binary and start it up to begin database replication. The `Litestream` GenServer
  expects a Keyword list with the following options:

  * `:repo` - The Ecto Repo that manages the SQLite database. REQUIRED
  * `:strategy` - The Litestream backup strategy you want to use. REQUIRED
  * `:name` - The name of the GenServer process. By default it is `Litestream`. OPTIONAL
  * `:bin_path` - If you already have access to the Litestream binary, provide the path via this
                  option so that you can skip the download step. OPTIONAL
  * `:version` - The version of Litestream that you want to download. OPTIONAL
  """
  def start_link(opts) do
    repo = Keyword.fetch!(opts, :repo)
    repo_config = repo.config()
    database_file = Keyword.fetch!(repo_config, :database)

    strategy =
      opts
      |> Keyword.fetch!(:strategy)
      |> maybe_create_temp_file(database_file)

    state = %{
      repo: repo,
      strategy: strategy,
      bin_path: Keyword.get(opts, :bin_path, :download),
      version: Keyword.get(opts, :version, Downloader.default_version())
    }

    GenServer.start_link(__MODULE__, state, name: Keyword.get(opts, :name, __MODULE__))
  end

  @doc """
  This function will return the status of the Litestream port with either a `:down` or
  `:running` atom.
  """
  def status(name \\ __MODULE__) do
    GenServer.call(name, :status, @call_timeout)
  end

  @doc """
  This function will cleanly stop the Litestream process, but the GenServer will still be
  running.
  """
  def stop_litestream(name \\ __MODULE__) do
    GenServer.call(name, :stop_litestream, @call_timeout)
  end

  @doc """
  This function will start the Litestream process, if it is not currently running. If it is
  already running, then this operation is effectively a no-op.
  """
  def start_litestream(name \\ __MODULE__) do
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
      |> Map.put(:otp_app, otp_app)
      |> Map.put(:database, database_file)
      |> clear_pids()

    if state.bin_path == :download do
      {:ok, updated_state, {:continue, :download_litestream}}
    else
      unless File.exists?(state.bin_path) do
        raise "The path to the Litestream binary does not exist: #{inspect(state.bin_path)}"
      end

      {:ok, updated_state, {:continue, :start_litestream}}
    end
  end

  @impl true
  def handle_continue(:download_litestream, %{otp_app: otp_app, version: version} = state) do
    otp_app_priv_dir = :code.priv_dir(otp_app)
    download_dir = Path.join(otp_app_priv_dir, "/litestream/download")
    bin_dir = Path.join(otp_app_priv_dir, "/litestream/bin")

    File.mkdir_p!(download_dir)
    File.mkdir_p!(bin_dir)

    bin_path =
      case Downloader.download(bin_dir, override_version: version) do
        {:ok, output_files, []} ->
          Enum.find(output_files, fn file ->
            String.ends_with?(file, "litestream")
          end)

        {:skip, bin_path} ->
          bin_path
      end

    updated_state = Map.put(state, :bin_path, bin_path)

    {:noreply, updated_state, {:continue, :start_litestream}}
  end

  def handle_continue(:start_litestream, state) do
    {:ok, port_pid, os_pid} =
      [
        state.bin_path,
        "replicate"
        | Replicator.cli_args(state.strategy, state.database)
      ]
      |> Enum.join(" ")
      |> :exec.run_link([
        :monitor,
        {:env,
         [
           :clear | Replicator.env_vars(state.strategy)
         ]},
        {:kill_timeout, 10},
        :stdout,
        :stderr
      ])

    updated_state =
      state
      |> Map.put(:port_pid, port_pid)
      |> Map.put(:os_pid, os_pid)

    {:noreply, updated_state}
  end

  @impl true
  def handle_call(:status, _from, %{os_pid: os_pid} = state) do
    if os_pid in :exec.which_children() do
      {:reply, :running, state}
    else
      {:reply, :down, state}
    end
  end

  def handle_call(:start_litestream, _from, %{os_pid: os_pid} = state) do
    if os_pid in :exec.which_children() do
      Logger.info("Litestream is already running")

      {:reply, :ok, state}
    else
      Logger.info("Starting Litestream")

      {:reply, :ok, state, {:continue, :start_litestream}}
    end
  end

  def handle_call(:stop_litestream, _from, %{port_pid: port_pid, os_pid: os_pid} = state) do
    if os_pid in :exec.which_children() do
      :ok = :exec.kill(port_pid, :sigterm)

      {:reply, :ok, clear_pids(state)}
    else
      Logger.info("Litestream is not running")

      {:reply, :ok, state}
    end
  end

  @impl true
  def handle_info({:EXIT, _os_pid, reason}, state) do
    Logger.info("Litestream has exited with reason: #{inspect(reason)}")

    {:noreply, clear_pids(state)}
  end

  def handle_info({:DOWN, _os_pid, _process, _pid, reason}, state) do
    Logger.info("Litestream has shutdown with reason: #{reason}")

    {:noreply, state}
  end

  def handle_info({:stdout, _os_pid, output}, state) do
    Logger.info(output)

    {:noreply, state}
  end

  def handle_info({:stderr, _os_pid, output}, state) do
    Logger.warning(output)

    {:noreply, state}
  end

  @impl true
  def terminate(reason, state) do
    Logger.info("Litestream is terminating with reason #{inspect(reason)}")

    # Clean up any temp files created by the strategies
    case state.strategy do
      %_{temp_config_path: config_path} ->
        File.rm(config_path)

      _ ->
        :no_op
    end

    :ok
  end

  # +------------------------------------------------------------------+
  # |                   Private Helper Functions                       |
  # +------------------------------------------------------------------+
  defp clear_pids(state) do
    state
    |> Map.put(:port_pid, nil)
    |> Map.put(:os_pid, nil)
  end

  defp maybe_create_temp_file(strategy, database) do
    case Replicator.temp_file_contents(strategy, database) do
      nil ->
        strategy

      file_contents ->
        temp_path = Path.join(System.tmp_dir!(), "litestream-#{:erlang.unique_integer([:positive])}.yml")
        File.write!(temp_path, file_contents)
        Map.put(strategy, :temp_config_path, temp_path)
    end
  end
end
