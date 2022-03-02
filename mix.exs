defmodule Litestream.MixProject do
  use Mix.Project

  def project do
    [
      app: :litestream,
      version: "0.1.0",
      elixir: "~> 1.13",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger, :inets, :crypto, :public_key]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:castore, ">= 0.0.0"},
      {:ex_doc, ">= 0.0.0", only: :docs}
    ]
  end
end
