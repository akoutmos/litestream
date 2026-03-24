defmodule Litestream.Strategy.ScalewayObjectStorage do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Scaleway's Object Storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %ScalewayObjectStorage{
          bucket: String.t(),
          path: String.t(),
          region: String.t(),
          access_key_id: String.t(),
          secret_access_key: String.t()
        }

  @required_keys [:bucket, :path, :region, :access_key_id, :secret_access_key]
  @enforce_keys @required_keys
  defstruct [:temp_config_path | @required_keys]

  defimpl Replicator do
    def env_vars(_struct) do
      []
    end

    def cli_args(%ScalewayObjectStorage{temp_config_path: config_path}, _database) do
      ["-config", config_path]
    end

    def temp_file_contents(
          %ScalewayObjectStorage{
            bucket: bucket,
            path: path,
            region: region,
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
            endpoint: s3.#{region}.scw.cloud
            region: #{region}
            access-key-id: #{access_key_id}
            secret-access-key: #{secret_access_key}
      """
    end
  end
end
