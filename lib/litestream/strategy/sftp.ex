defmodule Litestream.Strategy.SFTP do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to an
  SFTP server.
  """

  alias __MODULE__
  alias Litestream.Replicator

  defstruct [:user, :password, :host, :port, :path]

  defimpl Replicator do
    def env_vars(_) do
      []
    end

    def cli_args(%SFTP{user: user, password: password, host: host, port: port, path: path}, database) do
      [database, Path.join("sftp://#{user}:#{password}@#{host}:#{port}", path)]
    end
  end
end
