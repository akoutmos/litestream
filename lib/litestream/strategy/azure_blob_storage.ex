defmodule Litestream.Strategy.AzureBlobStorage do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to
  Azure's blob storage.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %AzureBlobStorage{
          account_key: String.t(),
          storage_account: String.t(),
          container_name: String.t(),
          path: String.t()
        }

  @keys [:account_key, :storage_account, :container_name, :path]
  @enforce_keys @keys
  defstruct @keys

  defimpl Replicator do
    def env_vars(%AzureBlobStorage{account_key: account_key}) do
      [
        {"LITESTREAM_AZURE_ACCOUNT_KEY", account_key}
      ]
    end

    def cli_args(
          %AzureBlobStorage{storage_account: storage_account, container_name: container_name, path: path},
          database
        ) do
      uri = %URI{
        scheme: "abs",
        userinfo: storage_account,
        host: container_name,
        path: path
      }

      [database, URI.to_string(uri)]
    end
  end
end
