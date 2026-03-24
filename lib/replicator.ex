defprotocol Litestream.Replicator do
  @moduledoc """
  This protocol defines what functions a strategy struct must
  implement.
  """

  @doc """
  This function should return a list of tuples where the first element in the
  tuple is the environment variable that will be passed to the Litestream process
  and the second element in the tuple is the value for the environment variable.
  """
  @spec env_vars(struct :: t()) :: list({env_var :: String.t(), value :: String.t()})
  def env_vars(struct)

  @doc """
  This function should create a list of CLI arguments that are passed to the
  Litestream binary.
  """
  @spec cli_args(struct :: t(), database :: String.t()) :: list(args :: String.t())
  def cli_args(struct, database)

  @doc """
  If the strategy requires a temporary file for it's configuration, this function
  will provide the
  """
  @spec temp_file_contents(struct :: t(), database :: String.t()) :: temp_file_contents :: String.t()
  def temp_file_contents(struct, database)
end
