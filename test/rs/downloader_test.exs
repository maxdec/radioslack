defmodule RS.DownloaderTest do
  use ExUnit.Case, async: true

  @sample_url "https://maxdec.fr/samplevideo_1mb.mp4"

  setup context do
    filename = "./samples/#{context.test}.mp4"
    File.rm(filename)

    on_exit fn -> File.rm(filename) end

    {:ok, filename: filename}
  end

  test "downloads the file at the given URL and returns a stream", %{filename: filename} do
    RS.Downloader.stream!(@sample_url)
    |> Enum.each(fn chunk -> File.write(filename, chunk, [:binary, :append]) end)

    assert File.exists?(filename)
    stats = File.lstat!(filename)
    assert stats.size > 1_000_000
  end
end
