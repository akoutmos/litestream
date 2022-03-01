defmodule LitestreamTest do
  use ExUnit.Case
  doctest Litestream

  test "greets the world" do
    assert Litestream.hello() == :world
  end
end
