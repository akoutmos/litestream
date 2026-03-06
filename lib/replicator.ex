defprotocol Litestream.Replicator do
  @spec env_vars(struct :: t()) :: list({env_var :: String.t(), value :: String.t()})
  def env_vars(struct)

  @spec cli_args(struct :: t(), database :: String.t()) :: list(args :: String.t())
  def cli_args(struct, database)
end
