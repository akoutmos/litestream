defmodule Litestream.Downloader do
  @moduledoc """
  This module is used to download the built Litestream binaries.
  """

  require Logger

  @latest_litestream_version "0.3.8"
  @supported_litestream_versions ["0.3.8", "0.3.7"]

  @valid_litestream_versions %{
    # All the SHA hashes for version 0.3.8
    {"0.3.8", :darwin, :amd64} => "d359a4edd1cb98f59a1a7c787bbd0ed30c6cc3126b02deb05a0ca501ff94a46a",
    {"0.3.8", :linux, :amd64} => "530723d95a51ee180e29b8eba9fee8ddafc80a01cab7965290fb6d6fc31381b3",
    {"0.3.8", :linux, :arm64} => "1d6fb542c65b7b8bf91c8859d99f2f48b0b3251cc201341281f8f2c686dd81e2",

    # All the SHA hashes for version 0.3.7
    {"0.3.7", :darwin, :amd64} => "fdfd811df081949fdac2f09af8ad624c37c02b98c0e777f725f69e67be270745",
    {"0.3.7", :linux, :amd64} => "e9daf0b73d7b5d75eac22bb9f0a93945e3efce0f1ff5f3a6b57f4341da4609cf",
    {"0.3.7", :linux, :arm64} => "1c0c1c6a2346fb67d69e594b6342e1d13f078d2b02a2c8bae4b84ea188b12579"
  }

  defguardp is_valid_version(version) when version in @supported_litestream_versions

  @doc """
  Get the latest version of Litestream (that is supported by the library).
  """
  @spec latest_version :: String.t()
  def latest_version do
    @latest_litestream_version
  end

  @doc """
  This function will download the desired Litestream version and store it in the
  provided directory..
  """
  @spec download_litestream(
          version :: String.t(),
          download_directory :: String.t(),
          bin_directory :: String.t()
        ) :: {:ok, String.t()} | {:error, String.t()}
  def download_litestream(litestream_version, download_directory, bin_directory)
      when is_valid_version(litestream_version) do
    litestream_version = get_download_version(litestream_version)
    download_url = build_download_url(litestream_version)

    archive_file_name =
      download_url
      |> URI.parse()
      |> Map.get(:path)
      |> Path.basename()

    binary_file_name =
      if String.ends_with?(archive_file_name, ".zip") do
        archive_file_name
        |> String.trim_trailing(".zip")
      else
        archive_file_name
        |> String.trim_trailing(".tar.gz")
      end

    # Set constants for where files will be located
    archive_download_path = "#{download_directory}/#{archive_file_name}"
    binary_path = "#{bin_directory}/#{binary_file_name}"

    # Download the litestream, verify it, and unarchive it
    with :ok <- do_download_litestream(download_url, archive_download_path),
         :ok <- verify_archive_download(archive_download_path, litestream_version) do
      unarchive_litestream(archive_download_path, binary_path)
    end
  end

  defp do_download_litestream(download_url, archive_file_path) do
    if File.exists?(archive_file_path) do
      Logger.info("Litestream archive already present")

      :ok
    else
      Logger.info("Fetching Litestream archive")

      # Ensure that the necessary applications have been started
      {:ok, _} = Application.ensure_all_started(:inets)
      {:ok, _} = Application.ensure_all_started(:ssl)

      if proxy = System.get_env("HTTP_PROXY") || System.get_env("http_proxy") do
        Logger.debug("Using HTTP_PROXY: #{proxy}")
        %{host: host, port: port} = URI.parse(proxy)
        :httpc.set_options([{:proxy, {{String.to_charlist(host), port}, []}}])
      end

      if proxy = System.get_env("HTTPS_PROXY") || System.get_env("https_proxy") do
        Logger.debug("Using HTTPS_PROXY: #{proxy}")
        %{host: host, port: port} = URI.parse(proxy)
        :httpc.set_options([{:https_proxy, {{String.to_charlist(host), port}, []}}])
      end

      # https://erlef.github.io/security-wg/secure_coding_and_deployment_hardening/inets
      cacertfile = CAStore.file_path() |> String.to_charlist()

      http_options = [
        ssl: [
          verify: :verify_peer,
          cacertfile: cacertfile,
          depth: 2,
          customize_hostname_check: [
            match_fun: :public_key.pkix_verify_hostname_match_fun(:https)
          ]
        ]
      ]

      options = [body_format: :binary]

      case :httpc.request(:get, {download_url, []}, http_options, options) do
        {:ok, {{_, 200, _}, _headers, body}} ->
          File.write!(archive_file_path, body)

        error ->
          raise "Could not fetch Litestream from #{download_url}: #{inspect(error)}"
      end

      :ok
    end
  end

  defp get_download_version(litestream_version) do
    arch_str = :erlang.system_info(:system_architecture)
    [arch | _] = arch_str |> List.to_string() |> String.split("-")

    case {:os.type(), arch, :erlang.system_info(:wordsize) * 8} do
      # TODO: When Litestream supports ARM macOS builds
      # {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> {litestream_version, :darwin, :arm64}
      {{:unix, :darwin}, arch, 64} when arch in ~w(arm aarch64) -> {litestream_version, :darwin, :amd64}
      {{:unix, :darwin}, "x86_64", 64} -> {litestream_version, :darwin, :amd64}
      {{:unix, :linux}, "aarch64", 64} -> {litestream_version, :linux, :arm64}
      {{:unix, _osname}, arch, 64} when arch in ~w(x86_64 amd64) -> {litestream_version, :linux, :amd64}
      unsupported_arch -> raise "Unsupported architecture: #{inspect(unsupported_arch)}"
    end
  end

  defp unarchive_litestream(archive_download_path, binary_path) do
    if String.ends_with?(archive_download_path, ".zip") do
      # Extract the zip file
      zip_contents = File.read!(archive_download_path)
      {:ok, [{_file_name, unzipped_contents}]} = :zip.extract(zip_contents, [:memory])

      # Set exec permissions to Litestream
      File.write(binary_path, unzipped_contents)
      File.chmod!(binary_path, 0o755)

      {:ok, binary_path}
    else
      # Extract the tarball
      tarball_contents = File.read!(archive_download_path)
      {:ok, [{_file_name, untarred_contents}]} = :erl_tar.extract({:binary, tarball_contents}, [:memory, :compressed])

      # Set exec permissions to Litestream
      File.write(binary_path, untarred_contents)
      File.chmod!(binary_path, 0o755)

      {:ok, binary_path}
    end
  end

  defp verify_archive_download(archive_download_path, litestream_version) do
    # Get the known SHA256 value
    known_sha = Map.fetch!(@valid_litestream_versions, litestream_version)

    # Read the archive file and compute the SHA256 value
    archive_contents = File.read!(archive_download_path)

    computed_sha =
      :sha256
      |> :crypto.hash(archive_contents)
      |> Base.encode16()
      |> String.downcase()

    if known_sha == computed_sha do
      :ok
    else
      {:error, "Invalid SHA256 value computed for #{archive_download_path}"}
    end
  end

  defp build_download_url({version, :darwin, arch}) do
    "https://github.com/benbjohnson/litestream/releases/download/v#{version}/litestream-v#{version}-darwin-#{arch}.zip"
  end

  defp build_download_url({version, :linux, arch}) do
    "https://github.com/benbjohnson/litestream/releases/download/v#{version}/litestream-v#{version}-linux-#{arch}.tar.gz"
  end
end
