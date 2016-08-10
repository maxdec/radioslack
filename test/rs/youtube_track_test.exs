defmodule RS.YoutubeTrackTest do
  use ExUnit.Case, async: true

  describe "RS.YoutubeTrack.video_id" do
    test "Extracts the video ID from a Track" do
      url = "https://www.youtube.com/watch?v=7FKEy_RWwQk"
      id = RS.YoutubeTrack.video_id(url)
      assert id == "7FKEy_RWwQk"
    end

    test "Returns nil for an incorrect URL" do
      url = "https://foo.com/watch?yolo=123"
      id = RS.YoutubeTrack.video_id(url)
      assert id == nil
    end
  end

  describe "RS.YoutubeTrack.youtube_info" do
    test "Retrieves the video streams as a list of maps" do
      url = "https://www.youtube.com/watch?v=7FKEy_RWwQk"
      {:ok, %RS.YoutubeTrack.YoutubeInfo{streams: streams, title: _title}} = RS.YoutubeTrack.youtube_info(url)
      assert is_list(streams)
      stream = List.first(streams)
      assert stream["fallback_host"]
      assert stream["quality"]
      assert stream["type"]
      assert stream["url"]
      assert stream["itag"]
    end

    test "RS.YoutubeTrack.youtube_streams returns an error if the request is invalid" do
      url = "https://foo.com/watch?yolo=123"
      assert {:error, _reason} = RS.YoutubeTrack.youtube_info(url)
    end
  end

  describe "RS.YoutubeTrack implements RS.Track" do
    test "audio_stream! returns the audio stream for the given Track", %{test: test} do
      filename = "./samples/#{test}.mp3"
      File.rm(filename)

      user = %{id: 123, name: "Max"}
      {:ok, track} = RS.YoutubeTrack.create("https://www.youtube.com/watch?v=cUVaBVjT4pk", user)
      RS.Playable.audio_stream!(track)
      |> Enum.each(fn chunk -> File.write(filename, chunk, [:binary, :append]) end)

      assert File.exists?(filename)
      stats = File.lstat!(filename)
      assert stats.size > 1_000
      File.rm(filename)
    end

    test "match? returns true for a YouTube URL, false otherwise" do
      assert RS.YoutubeTrack.match?("https://www.youtube.com/watch?v=123")
      assert RS.YoutubeTrack.match?("http://www.youtube.com/watch?v=123")
      assert RS.YoutubeTrack.match?("http://youtube.com/watch?v=123")
      assert !RS.YoutubeTrack.match?("http://dailymotion.com/watch?v=123")
    end
  end
end
