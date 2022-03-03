defmodule Litestream.MixProject do
  use Mix.Project

  def project do
    [
      app: :litestream,
      version: "0.1.0-beta",
      elixir: "~> 1.13",
      name: "Litestream",
      source_url: "https://github.com/akoutmos/litestream",
      homepage_url: "https://hex.pm/packages/litestream",
      description: "Add Litestream to your SQLite powered application for effortless backups",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package(),
      docs: docs()
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
      {:erlexec, "~> 1.19"},
      {:castore, "~> 0.1.15"},
      {:ex_doc, "~> 0.28.2", only: :dev, runtime: false}
    ]
  end

  defp package do
    [
      name: "litestream",
      files: ~w(lib mix.exs README.md),
      licenses: ["MIT"],
      maintainers: ["Alex Koutmos"],
      links: %{
        "GitHub" => "https://github.com/akoutmos/litestream",
        "Sponsor" => "https://github.com/sponsors/akoutmos"
      }
    ]
  end

  defp docs do
    [
      main: "readme",
      source_ref: "master",
      extras: [
        "README.md"
      ]
    ]
  end
end
