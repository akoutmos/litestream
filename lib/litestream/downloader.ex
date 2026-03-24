defmodule Litestream.Downloader do
  @moduledoc """
  This module is used to download the built Litestream binaries.
  """

  use OctoFetch,
    latest_version: "0.5.9",
    github_repo: "benbjohnson/litestream",
    download_versions: %{
      "0.5.9" => [
        {:darwin, :arm64, "1ccff96084d3e0faf4f8fabd22931fd774718f43b920480c48cbf366a558146d"},
        {:darwin, :amd64, "61750da940ba00dce5a582fc549848754270acc6dca7643a8afea5cf32d45e9d"},
        {:linux, :arm64, "330e290f98ecf00ac3b8b2e2f038d81ada2712da86a9466d3187f02ded269821"},
        {:linux, :amd64, "e8612ef5424802723e8cfa2d07a182df60f9af71839b5ff5ef1e80dff38efbdd"},
        {:windows, :arm64, "7bd96ec53d3b4fc3a4e5f312f751186a18db736c8c4600f5ebd2be70783703f7"},
        {:windows, :amd64, "f83b9ca924717b03fd44fed3463591f603e400e9b295ec0f463c2bb867f23bdb"}
      ],
      "0.5.8" => [
        {:darwin, :arm64, "9f70cf6c79b09bcc9943f3acde0e207d008dc38b218a2992f46d4d0d0f6c830b"},
        {:darwin, :amd64, "e4987bddd8b7ce8e176a22109d3e226a87c0df65bc1ffd1ed03f6ff0cdf78ffa"},
        {:linux, :arm64, "7417919b8df803b02ca511adbf401771830526c9b22dcde10b9ab04714a346ee"},
        {:linux, :amd64, "0a7234a3f1c8d0f1af95c3489c0012aba4b3d966bb12312bf61b65069873d853"},
        {:windows, :arm64, "07a1dc7894eb2955f4076a433345a9e2919dc9c154e4fc60ed88eaf0782c8c6f"},
        {:windows, :amd64, "6efb6b62794d216d7ace5f65383bb1bcdfad466b6e7278e806ea94731d625e36"}
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
  def download_name(version, :windows, :amd64), do: "litestream-#{version}-windows-x86_64.zip"
  def download_name(version, :windows, :arm64), do: "litestream-#{version}-windows-arm64.zip"
  def download_name(version, os, :amd64), do: "litestream-#{version}-#{os}-x86_64.tar.gz"
  def download_name(version, os, arch), do: "litestream-#{version}-#{os}-#{arch}.tar.gz"
end
