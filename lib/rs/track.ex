defmodule RS.TrackBuilder do
  @spec create(String.t) :: {:ok, RS.Playable.t}|{:error, String.t}
  def create(url) do
    cond do
      RS.YoutubeTrack.match?(url) -> RS.YoutubeTrack.create(url)
      RS.FileTrack.match?(url) -> RS.FileTrack.create(url)
      RS.SoundcloudTrack.match?(url) -> RS.SoundcloudTrack.create(url)
      true -> {:error, "Track not recognized or not supported"}
    end
  end
end

defmodule RS.Track do
  @callback match?(String.t) :: true|false
  @callback create(String.t) :: {:ok, RS.Playable.t}|{:error, String.t}
end

defprotocol RS.Playable do
  @doc """
  Returns an audio stream
  """
  @spec audio_stream!(RS.Playable.t) :: Enumerable.t
  def audio_stream!(track)
end
