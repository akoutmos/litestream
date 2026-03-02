defprotocol Litestream.Replicator do
  @spec env_vars(t) :: list({env_var :: String.t(), value :: String.t()})
  def env_vars(struct)

  @spec cli_args(t) :: list(args :: String.t())
  def cli_args(struct)
end
