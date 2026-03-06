defmodule Litestream.Strategy.ObjectStorage do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to an object
  store like AWS S3, Digital Ocean Spaces, Tigris, etc.
  """

  alias __MODULE__
  alias Litestream.Replicator

  defstruct [:access_key_id, :secret_access_key, :url]

  defimpl Replicator do
    def env_vars(%ObjectStorage{access_key_id: access_key_id, secret_access_key: secret_access_key}) do
      [
        {"AWS_ACCESS_KEY_ID", access_key_id},
        {"AWS_SECRET_ACCESS_KEY", secret_access_key}
      ]
    end

    def cli_args(%ObjectStorage{url: url}, database) do
      [database, url]
    end
  end
end
