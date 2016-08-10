defmodule RS.YoutubeTrack do
  @behaviour RS.Track

  defstruct [url: "", type: :youtube, title: "", stream_url: "", duration: ~T[00:00:00], picture_url: "", user: %{}]

  defmodule YoutubeInfo do
    defstruct [streams: [], protected: false, title: "", duration: 0, pictures: %{}]
  end

  @doc """
  Returns the video ID extracted from the URL.
  """
  @spec video_id(String.t) :: String.t
  def video_id(url) do
    url
    |> URI.parse
    |> Map.get(:query)
    |> URI.decode_query
    |> Map.get("v")
  end

  @spec youtube_info(String.t) :: {:ok, %YoutubeInfo{}}|{:error, String.t}
  def youtube_info(url) do
    v_id = video_id(url)
    info_url = 'http://www.youtube.com/get_video_info?video_id=#{v_id}'

    case HTTPoison.get(info_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        decoded_body = URI.decode_query(body)
        cond do
          decoded_body["errorcode"] -> {:error, decoded_body["reason"]}
          true -> create_info(decoded_body)
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Could not retrieve the download URL: status code #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec match?(String.t) :: true|false
  def match?(url), do: Regex.match?(~r/^https?:\/\/(www.)?youtube\.com/, url)

  @spec create(String.t, %{}) :: {:ok, %RS.YoutubeTrack{}}|{:error, String.t}
  def create(url, user) do
    case youtube_info(url) do
      {:ok, %{protected: true}} -> {:error, "This video is protected with cipher signature"}
      {:ok, %{streams: []}} -> {:error, "Could not retrieve the download URL"}
      {:ok, info} -> {:ok, create_track(info, url, user)}
      {:error, _} = error -> error
    end
  end

  @spec create_info(%{}) :: {:ok, %YoutubeInfo{}}
  defp create_info(body) do
    {duration, _} = Integer.parse(body["length_seconds"])

    streams = (body["url_encoded_fmt_stream_map"] || "")
    |> String.split(",")
    |> Enum.map(&URI.decode_query/1)

    {:ok, %YoutubeInfo{
      streams: streams,
      protected: body["use_cipher_signature"] == "True",
      title: body["title"],
      duration: duration,
      pictures: %{
        standard: body["iurl"],
        max: body["iurlmaxres"],
        high: body["iurlhq"],
        medium: body["iurlmq"],
        small: body["iurlsd"],
      }
    }}
  end

  @spec create_track(%YoutubeInfo{}, String.t, %{}) :: %RS.YoutubeTrack{}
  defp create_track(%YoutubeInfo{} = info, url, user) do
    %RS.YoutubeTrack{
      url: url,
      stream_url: List.first(info.streams)["url"],
      title: info.title,
      duration: RS.Utils.duration_to_time(info.duration),
      picture_url: info.pictures.standard,
      user: user
    }
  end
end

defimpl RS.Playable, for: RS.YoutubeTrack do
  @spec audio_stream!(%RS.YoutubeTrack{}) :: Stream.t
  def audio_stream!(%RS.YoutubeTrack{stream_url: stream_url}) do
    stream_url
    |> RS.Downloader.stream!
    |> RS.AudioExtractor.extract!
  end
end
