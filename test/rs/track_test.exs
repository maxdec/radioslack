defmodule RS.TrackTest do
  use ExUnit.Case, async: true

  describe "Create Tracks" do
    test "it returns a YoutubeTrack" do
      url = "https://www.youtube.com/watch?v=7FKEy_RWwQk"
      user = %{id: 123, name: "Max"}
      assert {:ok, %RS.YoutubeTrack{url: ^url}} = RS.TrackBuilder.create(url, user)
    end

    test "it returns a FileTrack" do
      url = "./samples/sample_audio_full.mp3"
      user = %{id: 123, name: "Max"}
      assert {:ok, %RS.FileTrack{url: ^url}} = RS.TrackBuilder.create(url, user)
    end

    test "it returns an error if the given `url` is unknown or not supported" do
      url = "---"
      user = %{id: 123, name: "Max"}
      assert {:error, _msg} = RS.TrackBuilder.create(url, user)
    end
  end
end
