defmodule Litestream.MixProject do
  use Mix.Project

  def project do
    [
      app: :litestream,
      version: "0.3.0",
      elixir: "~> 1.13",
      name: "Litestream",
      source_url: "https://github.com/akoutmos/litestream",
      homepage_url: "https://hex.pm/packages/litestream",
      description: "Add Litestream to your SQLite powered application for effortless backups",
      start_permanent: Mix.env() == :prod,
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test,
        "coveralls.github": :test
      ],
      deps: deps(),
      package: package(),
      docs: docs(),
      aliases: aliases()
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
      # Required dependencies
      {:erlexec, "~> 2.0"},
      {:castore, "~> 0.1.15"},

      # Development related dependencies
      {:ex_doc, "~> 0.28.2", only: :dev},
      {:excoveralls, "~> 0.14.4", only: :test, runtime: false},
      {:doctor, "~> 0.18.0", only: :dev},
      {:credo, "~> 1.6.1", only: :dev},
      {:git_hooks, "~> 0.6.4", only: [:test, :dev], runtime: false}
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
      logo: "guides/images/logo.svg",
      extras: [
        "README.md"
      ]
    ]
  end

  defp aliases do
    [
      docs: ["docs", &copy_files/1]
    ]
  end

  defp copy_files(_) do
    # Set up directory structure
    File.mkdir_p!("./doc/guides/images")

    # Copy over image files
    "./guides/images/"
    |> File.ls!()
    |> Enum.each(fn image_file ->
      File.cp!("./guides/images/#{image_file}", "./doc/guides/images/#{image_file}")
    end)
  end
end
