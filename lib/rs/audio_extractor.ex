defmodule RS.AudioExtractor do
  if Mix.env == :test do
    @cmd "ffmpeg -i pipe:0 -b:a 128k -map a -f mp3 pipe:1"
  else
    @cmd "ffmpeg -re -i pipe:0 -b:a 128k -map a -f mp3 pipe:1"
  end

  def extract!(instream) do
    opts = [in: instream, out: :stream]
    %{err: error, out: outstream} = Porcelain.spawn_shell(@cmd, opts)
    if error, do: throw error
    outstream
  end
end
