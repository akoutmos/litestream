<p align="center">
  <img align="center" width="25%" src="guides/images/logo.svg" alt="Litestream Elixir Logo">
  <img align="center" width="50%" src="guides/images/logo_name.png" alt="Litestream title">
</p>

<p align="center">
  Easily backup your SQLite database right from Elixir using <a href="https://litestream.io/" target="_blank">Litestream</a>
</p>

<p align="center">
  <a href="https://hex.pm/packages/litestream">
    <img alt="Hex.pm" src="https://img.shields.io/hexpm/v/litestream?style=for-the-badge">
  </a>

  <a href="https://github.com/akoutmos/litestream/actions">
    <img alt="GitHub Workflow Status (master)"
    src="https://img.shields.io/github/workflow/status/akoutmos/litestream/Litestream%20CI/master?label=Build%20Status&style=for-the-badge">
  </a>

  <a href="https://github.com/sponsors/akoutmos">
    <img alt="Support the project" src="https://img.shields.io/badge/Support%20the%20project-%E2%9D%A4-lightblue?style=for-the-badge">
  </a>
</p>

<br>

# Contents

- [Installation](#installation)
- [Supporting Litestream](#supporting-litestream)
- [Setting Up Litestream](#setting-up-litestream)
- [Attribution](#attribution)

## Installation

[Available in Hex](https://hex.pm/packages/Litestream), the package can be installed by adding `litestream` to your list of
dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:litestream, "~> 0.1.0"}
  ]
end
```

Documentation can be found at [https://hexdocs.pm/litestream](https://hexdocs.pm/litestream).

## Supporting Litestream

If you rely on this library to backup your SQLite databases, it would much appreciated if you can give back to the
project in order to help ensure its continued development.

Checkout my [GitHub Sponsorship page](https://github.com/sponsors/akoutmos) if you want to help out!

### Gold Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58083">
  <img align="center" height="175" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Silver Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=58082">
  <img align="center" height="150" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

### Bronze Sponsors

<a href="https://github.com/sponsors/akoutmos/sponsorships?sponsor=akoutmos&tier_id=17615">
  <img align="center" height="125" src="guides/images/your_logo_here.png" alt="Support the project">
</a>

## Setting Up Litestream

After adding `{:litestream, "~> 0.1.0"}` in your `mix.exs` file and running `mix deps.get`, open your `application.ex`
file and add the following to your supervision tree:

```elixir
@impl true
def start(_type, _args) do
  children = [
    # Start the Ecto repository
    LitescaleTest.Repo,
    {Litestream, litestream_config()},
    ...
  ]

  opts = [strategy: :one_for_one, name: MyApp.Supervisor]
  Supervisor.start_link(children, opts)
end

defp litestream_config do
  Application.get_env(:my_app, Litestream)
end
```

In your `runtime.exs` (or `dev.exs` if you are just developing locally):

```elixir
config :my_app, Litestream,
  repo: MyApp.Repo,
  replica_url: System.fetch_env!("REPLICA_URL"),
  access_key_id: System.fetch_env!("ACCESS_KEY_ID"),
  secret_access_key: System.fetch_env!("SECRET_ACCESS_KEY")
```

With those in place, you should be all set to go! As soon as your application starts, your database will be
automatically synced with your remote destination.

## Attribution

- The logo for the project is an edited version of an SVG image from the [unDraw project](https://undraw.co/)
- The Litestream library that this library wraps [Litestream](https://litestream.io)
