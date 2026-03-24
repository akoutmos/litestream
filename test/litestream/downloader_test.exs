defmodule Litestream.DownloaderTest do
  use ExUnit.Case

  alias Litestream.Downloader

  describe "Litestream.Downloader" do
    test "should be able to download all of the listed versions" do
      OctoFetch.Test.test_all_supported_downloads(Downloader)
    end
  end
end
