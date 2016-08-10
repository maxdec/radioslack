defmodule RS.FileTrackTest do
  use ExUnit.Case, async: true

  describe "#is_supported?" do
    test "Returns true if the filename ends with a supported extension" do
      url = "./foo.mp3"
      assert RS.FileTrack.is_supported?(url) == true
    end

    test "Returns false if the filename doesn't end with a supported extension" do
      url = "./foo.mp4"
      assert RS.FileTrack.is_supported?(url) == false
    end
  end

  describe "#match?" do
    test "returns true for a valid and supported File URL, false otherwise" do
      assert RS.FileTrack.match?("./samples/sample_audio_full.mp3")
      assert !RS.FileTrack.match?("./samples/sample_video_1mb.mp4")
      assert !RS.FileTrack.match?("./samples/does_not_exist.mp3")
    end
  end

  describe "#create" do
    test "returns a new FileTrack" do
      user = %{id: 123, name: "Max"}
      assert {:ok, %RS.FileTrack{}} = RS.FileTrack.create("./samples/sample_audio_full.mp3", user)
    end
  end

  describe "RS.FileTrack implements RS.Track" do
    test "audio_stream! returns the audio stream for the given Track", %{test: test} do
      filename = "./samples/#{test}.mp3"
      File.rm(filename)

      user = %{id: 123, name: "Max"}
      {:ok, track} = RS.FileTrack.create("./samples/sample_audio_full.mp3", user)
      RS.Playable.audio_stream!(track)
      |> Enum.each(fn chunk -> File.write(filename, chunk, [:binary, :append]) end)

      assert File.exists?(filename)
      stats = File.lstat!(filename)
      assert stats.size > 1_000_000
      File.rm(filename)
    end
  end
end
