defmodule Litestream.Strategy.NatsJetstream do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to a
  NATS JetStream Object Store.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %NatsJetstream{
          url: String.t(),
          bucket: String.t()
        }

  defstruct [:url, :bucket]

  defimpl Replicator do
    def env_vars(%NatsJetstream{url: url}) do
      [{"NATS_URL", url}]
    end

    def cli_args(%NatsJetstream{url: url, bucket: bucket}, database) do
      [database, Path.join(url, bucket)]
    end
  end
end
