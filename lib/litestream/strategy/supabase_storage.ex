defmodule Litestream.Strategy.SupabaseStorage do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Suprabase Storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %SupabaseStorage{
          access_key_id: String.t(),
          secret_access_key: String.t(),
          bucket: String.t(),
          path: String.t(),
          project_ref: String.t()
        }

  @keys [:access_key_id, :secret_access_key, :bucket, :path, :project_ref]
  @enforce_keys @keys
  defstruct @keys

  defimpl Replicator do
    def env_vars(%SupabaseStorage{access_key_id: access_key_id, secret_access_key: secret_access_key}) do
      [
        {"AWS_ACCESS_KEY_ID", access_key_id},
        {"AWS_SECRET_ACCESS_KEY", secret_access_key}
      ]
    end

    def cli_args(%SupabaseStorage{bucket: bucket, path: path, project_ref: project_ref}, database) do
      uri = %URI{
        scheme: "s3",
        host: "#{bucket}.linodeobjects.com",
        path: path,
        query: [endpoint: "#{project_ref}.supabase.co/storage/v1/s3"]
      }

      [database, URI.to_string(uri)]
    end
  end
end
