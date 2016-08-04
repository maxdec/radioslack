defmodule RS.FileTrack do
  @behaviour RS.Track

  defstruct [url: "", type: :file, title: "", picture_url: ""] #, :owner]

  @doc """
  Returns a list of supported extensions like [".mp3"]
  """
  @spec supported_extensions :: [atom]
  def supported_extensions, do: [:mp3]

  @spec is_supported?(String.t) :: true|false
  def is_supported?(url) do
    supported_extensions
    |> Enum.map(&(".#{&1}"))
    |> Enum.member?(Path.extname(url))
  end

  @spec match?(String.t) :: true|false
  def match?(url) do
    File.exists?(url) && RS.FileTrack.is_supported?(url)
  end

  @spec create(String.t) :: {:ok, %RS.FileTrack{}}|{:error, String.t}
  def create(url) do
    # ffprobe...
    {:ok, %RS.FileTrack{url: url, title: Path.basename(url, Path.extname(url))}}
  end
end

defimpl RS.Playable, for: RS.FileTrack do
  @spec audio_stream!(%RS.FileTrack{}) :: Stream.t
  def audio_stream!(%RS.FileTrack{url: url}) do
    File.stream!(url, [], 2048)
  end
end
