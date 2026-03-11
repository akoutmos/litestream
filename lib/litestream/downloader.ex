defmodule Litestream.Downloader do
  @moduledoc """
  This module is used to download the built Litestream binaries.
  """

  use OctoFetch,
    latest_version: "0.5.8",
    github_repo: "benbjohnson/litestream",
    download_versions: %{
      "0.5.8" => [
        {:darwin, :arm64, "9f70cf6c79b09bcc9943f3acde0e207d008dc38b218a2992f46d4d0d0f6c830b"},
        {:darwin, :amd64, "e4987bddd8b7ce8e176a22109d3e226a87c0df65bc1ffd1ed03f6ff0cdf78ffa"},
        {:linux, :arm64, "7417919b8df803b02ca511adbf401771830526c9b22dcde10b9ab04714a346ee"},
        {:linux, :armv6, "818d76de4e2fe501f670b069aa2865e6e939bd7fde912967bdb9ad779c37b3fa"},
        {:linux, :armv7, "6850186eb9f90fb63afde336bd12926fcd018bf6eecda9a0b26b1050c2a7aae2"},
        {:linux, :amd64, "0a7234a3f1c8d0f1af95c3489c0012aba4b3d966bb12312bf61b65069873d853"}
      ]
    }

  @impl true
  def pre_download_hook(_file, output_dir) do
    output_binary = Path.join(output_dir, "litestream")

    if File.exists?(output_binary) do
      {:skip, output_binary}
    else
      :cont
    end
  end

  @impl true
  def post_write_hook(file) do
    if String.ends_with?(file, "litestream") do
      File.chmod!(file, 0o755)
    else
      File.rm!(file)
    end

    :ok
  end

  @impl true
  def download_name(version, os, "amd64"), do: "litestream-#{version}-#{os}-x84_64.tar.gz"
  def download_name(version, os, arch), do: "litestream-#{version}-#{os}-#{arch}.tar.gz"
end
