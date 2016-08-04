defmodule RS.SoundcloudTrackTest do
  use ExUnit.Case, async: true

  describe "RS.SoundcloudTrack.soundcloud_info" do
    test "Retrieves the video info from Soundcloud API" do
      url = "https://soundcloud.com/hobta/jonasstrase_hobtavictoro"
      {:ok, %RS.SoundcloudTrack.SoundcloudInfo{} = info} = RS.SoundcloudTrack.soundcloud_info(url)
      assert is_list(info.streams)
      assert List.first(info.streams)
      assert !info.protected
      assert info.duration == 1597
      assert info.pictures.standard
    end

    test "RS.SoundcloudTrack.soundcloud_info returns an error if the request is invalid" do
      url = "https://foo.com/watch?yolo=123"
      assert {:error, _reason} = RS.SoundcloudTrack.soundcloud_info(url)
    end
  end

  describe "RS.SoundcloudTrack implements RS.Track" do
    test "audio_stream! returns the audio stream for the given Track", %{test: test} do
      filename = "./samples/#{test}.mp3"
      File.rm(filename)

      {:ok, track} = RS.SoundcloudTrack.create("https://soundcloud.com/kvass-1/kvass-geht-ab-pan-pot-mobilee")
      RS.Playable.audio_stream!(track)
      |> Enum.each(fn chunk -> File.write(filename, chunk, [:binary, :append]) end)

      assert File.exists?(filename)
      stats = File.lstat!(filename)
      assert stats.size > 1_000
      File.rm(filename)
    end

    test "match? returns true for a Soundcloud URL, false otherwise" do
      assert RS.SoundcloudTrack.match?("https://soundcloud.com/hobta/jonasstrase_hobtavictoro")
      assert RS.SoundcloudTrack.match?("http://soundcloud.com/hobta/jonasstrase_hobtavictoro")
      assert RS.SoundcloudTrack.match?("https://www.soundcloud.com/hobta/jonasstrase_hobtavictoro")
      assert !RS.SoundcloudTrack.match?("http://dailymotion.com/watch?v=123")
    end
  end
end
