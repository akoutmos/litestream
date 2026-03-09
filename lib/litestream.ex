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
  * `:bin_path` - If you already have access to the Litestream binary, provide the path via this
                  option so that you can skip the download step. OPTIONAL
  * `:endpoint` - The endpoint URL for S3-compatible storage (e.g. Cloudflare R2). When provided,
                  a config file will be used instead of CLI arguments. OPTIONAL
  * `:region` - The region for S3-compatible storage. Defaults to "auto" when endpoint is set.
                Only used when `:endpoint` is provided. OPTIONAL
  * `:bucket` - The bucket name. Required when `:endpoint` is provided, as the bucket cannot
                be inferred from the URL in that case. OPTIONAL
  * `:replica_path` - The path within the bucket. Required when `:endpoint` is provided. OPTIONAL
  """
  def start_link(opts) do
    state = %{
      repo: Keyword.fetch!(opts, :repo),
      replica_url: Keyword.get(opts, :replica_url),
      access_key_id: Keyword.fetch!(opts, :access_key_id),
      secret_access_key: Keyword.fetch!(opts, :secret_access_key),
      bin_path: Keyword.get(opts, :bin_path, :download),
      version: Keyword.get(opts, :version, Downloader.default_version()),
      override_architecture: Keyword.get(opts, :override_architecture, :x86_64),
      endpoint: Keyword.get(opts, :endpoint),
      region: Keyword.get(opts, :region, "auto"),
      bucket: Keyword.get(opts, :bucket),
      replica_path: Keyword.get(opts, :replica_path, ""),
      config_path: nil
    }

    validate_opts!(state)

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
  def handle_continue(:download_litestream, %{otp_app: otp_app, version: version, override_architecture: override_architecture} = state) do
    otp_app_priv_dir = :code.priv_dir(otp_app)
    download_dir = Path.join(otp_app_priv_dir, "/litestream/download")
    bin_dir = Path.join(otp_app_priv_dir, "/litestream/bin")

    File.mkdir_p!(download_dir)
    File.mkdir_p!(bin_dir)

    bin_path =
      Downloader.download(
        bin_dir,
        override_version: version,
        override_architecture: override_architecture
      )
      |> case do
        {:ok, [bin_path | _], []} -> bin_path
        :skip -> Path.join(bin_dir, "litestream")
      end

    updated_state = Map.put(state, :bin_path, bin_path)

    {:noreply, updated_state, {:continue, :start_litestream}}
  end

  def handle_continue(:start_litestream, state) do
    {cmd, env, updated_state} = build_command(state)

    {:ok, port_pid, os_pid} =
      :exec.run_link(
        cmd,
        [
          :monitor,
          {:env, [:clear] ++ env},
          {:kill_timeout, 10},
          :stdout,
          :stderr
        ]
      )

    updated_state =
      updated_state
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
  def terminate(reason, %{config_path: config_path} = _state) do
    Logger.info("Litestream is terminating with reason #{inspect(reason)}")

    if config_path && File.exists?(config_path) do
      File.rm(config_path)
    end

    :ok
  end

  # +------------------------------------------------------------------+
  # |                   Private Helper Functions                       |
  # +------------------------------------------------------------------+

  defp build_command(%{endpoint: nil} = state) do
    # Simple S3 case — use CLI shorthand, pass credentials via env
    cmd = "#{state.bin_path} replicate #{state.database} #{state.replica_url}"

    env = [
      {"LITESTREAM_ACCESS_KEY_ID", state.access_key_id},
      {"LITESTREAM_SECRET_ACCESS_KEY", state.secret_access_key}
    ]

    {cmd, env, state}
  end

  defp build_command(%{endpoint: endpoint} = state) when is_binary(endpoint) do
    # S3-compatible case (e.g. Cloudflare R2) — requires a config file
    config_path = Path.join(System.tmp_dir!(), "litestream-#{:erlang.unique_integer([:positive])}.yml")

    config = """
    dbs:
      - path: #{state.database}
        replicas:
          - type: s3
            bucket: #{state.bucket}
            path: #{state.replica_path}
            region: #{state.region}
            endpoint: #{state.endpoint}
            access-key-id: #{state.access_key_id}
            secret-access-key: #{state.secret_access_key}
    """

    File.write!(config_path, config)

    cmd = "#{state.bin_path} replicate -config #{config_path}"

    {cmd, [], Map.put(state, :config_path, config_path)}
  end

  defp validate_opts!(%{endpoint: nil, replica_url: nil}) do
    raise ArgumentError, "`:replica_url` is required when `:endpoint` is not set"
  end

  defp validate_opts!(%{endpoint: endpoint, bucket: nil}) when is_binary(endpoint) do
    raise ArgumentError, "`:bucket` is required when `:endpoint` is set"
  end

  defp validate_opts!(_state), do: :ok

  defp clear_pids(state) do
    state
    |> Map.put(:port_pid, nil)
    |> Map.put(:os_pid, nil)
  end
end
