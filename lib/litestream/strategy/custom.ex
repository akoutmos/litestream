defmodule Litestream.Strategy.Custom do
  @moduledoc """
  Use this strategy for backing up your SQLite DB file using a custom
  configuration file.
  """

  alias __MODULE__
  alias Litestream.Replicator

  @type t :: %Custom{
          config_path: String.t()
        }

  defstruct [:config_path]

  defimpl Replicator do
    def env_vars(_) do
      []
    end

    def cli_args(%Custom{config_path: config_path}, _database) do
      ["-config", config_path]
    end
  end
end
