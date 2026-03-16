defmodule Litestream.Strategy.CloudflareR2 do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Cloudflare's R2 Object storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %CloudflareR2{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          bucket: String.t()
        }

  @required_keys [:access_key_id, :secret_access_key, :bucket]
  @enforce_keys @required_keys
  defstruct [:temp_config_path | @required_keys]

  defimpl Replicator do
    def env_vars(_struct) do
      []
    end

    def cli_args(%CloudflareR2{temp_config_path: config_path}, _database) do
      ["-config", config_path]
    end

    def temp_file_contents(%CloudflareR2{}, _database) do
      """
      """
    end
  end
end
