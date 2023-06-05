defmodule Litestream.Downloader do
  @moduledoc """
  This module is used to download the built Litestream binaries.
  """

  use OctoFetch,
    latest_version: "0.3.9",
    github_repo: "benbjohnson/litestream",
    download_versions: %{
      "0.3.9" => [
        {:darwin, :amd64, "74599a34dc440c19544f533be2ef14cd4378ec1969b9b4fcfd24158946541869"},
        {:linux, :amd64, "806e1cca4a2a105a36f219a4c212a220569d50a8f13f45f38ebe49e6699ab99f"},
        {:linux, :arm64, "61acea9d960633f6df514972688c47fa26979fbdb5b4e81ebc42f4904394c5c5"}
      ],
      "0.3.8" => [
        {:darwin, :amd64, "d359a4edd1cb98f59a1a7c787bbd0ed30c6cc3126b02deb05a0ca501ff94a46a"},
        {:linux, :amd64, "530723d95a51ee180e29b8eba9fee8ddafc80a01cab7965290fb6d6fc31381b3"},
        {:linux, :arm64, "1d6fb542c65b7b8bf91c8859d99f2f48b0b3251cc201341281f8f2c686dd81e2"}
      ],
      "0.3.7" => [
        {:darwin, :amd64, "fdfd811df081949fdac2f09af8ad624c37c02b98c0e777f725f69e67be270745"},
        {:linux, :amd64, "e9daf0b73d7b5d75eac22bb9f0a93945e3efce0f1ff5f3a6b57f4341da4609cf"},
        {:linux, :arm64, "1c0c1c6a2346fb67d69e594b6342e1d13f078d2b02a2c8bae4b84ea188b12579"}
      ]
    }

  require Logger

  @impl true
  def pre_download_hook(_file, output_dir) do
    if File.exists?(Path.join(output_dir, "litestream")) do
      :skip
    else
      :cont
    end
  end

  @impl true
  def post_write_hook(litestream_executable) do
    File.chmod!(litestream_executable, 0o755)

    :ok
  end

  @impl true
  def download_name(version, :darwin, arch), do: "litestream-v#{version}-darwin-#{arch}.zip"
  def download_name(version, :linux, arch), do: "litestream-v#{version}-linux-#{arch}.tar.gz"
end
