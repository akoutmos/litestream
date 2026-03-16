defmodule Litestream.Strategy.GoogleCloudStorage do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Google Cloud Storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %GoogleCloudStorage{
          credentials_file_path: String.t(),
          bucket: String.t(),
          path: String.t()
        }

  @keys [:credentials_file_path, :bucket, :path]
  @enforce_keys @keys
  defstruct @keys

  defimpl Replicator do
    def env_vars(%GoogleCloudStorage{credentials_file_path: credentials_file_path}) do
      [
        {"GOOGLE_APPLICATION_CREDENTIALS", credentials_file_path}
      ]
    end

    def cli_args(%GoogleCloudStorage{bucket: bucket, path: path}, database) do
      uri = %URI{
        scheme: "gs",
        host: bucket,
        path: path
      }

      [database, URI.to_string(uri)]
    end
  end
end
