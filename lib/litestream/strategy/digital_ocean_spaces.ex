defmodule Litestream.Strategy.DigitalOceanSpaces do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  DigitalOcean Spaces.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %DigitalOceanSpaces{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          space_name: String.t(),
          region: String.t(),
          path: String.t()
        }

  @keys [:access_key_id, :secret_access_key, :space_name, :region, :path]
  @enforce_keys @keys
  defstruct @keys

  defimpl Replicator do
    def env_vars(%DigitalOceanSpaces{access_key_id: access_key_id, secret_access_key: secret_access_key}) do
      [
        {"LITESTREAM_ACCESS_KEY_ID", access_key_id},
        {"LITESTREAM_SECRET_ACCESS_KEY", secret_access_key}
      ]
    end

    def cli_args(%DigitalOceanSpaces{space_name: space_name, region: region, path: path}, database) do
      uri = %URI{
        scheme: "s3",
        host: "#{space_name}.#{region}.digitaloceanspaces.com",
        path: path
      }

      [database, URI.to_string(uri)]
    end
  end
end
