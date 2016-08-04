defmodule RS.AudioExtractorTest do
  use ExUnit.Case, async: true

  setup context do
    filename = "./samples/#{context.test}.mp3"
    File.rm(filename)

    on_exit fn -> File.rm(filename) end

    {:ok, filename: filename}
  end

  test "transforms a stream of video+audio into an audio-only stream", %{filename: filename} do
    File.stream!("./samples/test_video_30s.mp4", [], 2048)
    |> RS.AudioExtractor.extract!
    |> Enum.each(fn chunk ->
      File.write(filename, chunk, [:binary, :append])
    end)

    assert File.exists?(filename)
    stats = File.lstat!(filename)
    assert stats.size > 1_000
  end

  # test "transforms a stream of video/audio into an audio-only stream", %{filename: filename} do
  #   File.stream!("./samples/sample_video_1mb.mp4")
  #   |> RS.AudioExtractor.extract!
  #   |> Stream.run
  # end
end
