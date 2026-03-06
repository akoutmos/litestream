defmodule Litestream.Strategy.LocalFile do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file to a local file.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %LocalFile{
          backup_path: String.t()
        }

  defstruct [:backup_path]

  defimpl Replicator do
    def env_vars(_) do
      []
    end

    def cli_args(%LocalFile{backup_path: backup_path}, database) do
      [database, "file://" <> backup_path]
    end
  end
end
