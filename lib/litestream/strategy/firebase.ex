defmodule Litestream.Strategy.Firebase do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Cloudflare's R2 object storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %Firebase{
          bucket: String.t(),
          path: String.t(),
          access_key_id: String.t(),
          secret_access_key: String.t()
        }

  @required_keys [:bucket, :path, :access_key_id, :secret_access_key]
  @enforce_keys @required_keys
  defstruct [:temp_config_path | @required_keys]

  defimpl Replicator do
    def env_vars(_struct) do
      []
    end

    def cli_args(%Firebase{temp_config_path: config_path}, _database) do
      ["-config", config_path]
    end

    def temp_file_contents(
          %Firebase{
            bucket: bucket,
            path: path,
            access_key_id: access_key_id,
            secret_access_key: secret_access_key
          },
          database
        ) do
      """
      dbs:
        - path: #{database}
          replica:
            type: s3
            bucket: #{bucket}
            path: #{path}
            endpoint: s3.filebase.com
            region: us-east-1
            access-key-id: #{access_key_id}
            secret-access-key: #{secret_access_key}
      """
    end
  end
end
