defmodule RS.SoundcloudTrack do
  @behaviour RS.Track

  defstruct [url: "", type: :soundcloud, title: "", stream_url: "", picture_url: ""]#, :owner]

  defmodule SoundcloudInfo do
    defstruct [streams: [], protected: false, title: "", duration: 0, pictures: %{}]
  end

  @doc """
  Retrieves the info about the given Soundcloud URL using the /resolve endpoint.
  """
  @spec soundcloud_info(String.t) :: {:ok, %SoundcloudInfo{}}|{:error, String.t}
  def soundcloud_info(url) do
    client_id = Application.fetch_env!(:rs, :soundcloud_client_id)
    info_url = "https://api.soundcloud.com/resolve?url=#{url}&client_id=#{client_id}"

    case HTTPoison.get(info_url) do
      {:ok, %HTTPoison.Response{status_code: 302, headers: headers}} ->
        case Enum.find(headers, fn {k, _v} -> k == "Location" end) do
          nil -> {:error, "Could not retrieve the details of the track"}
          {_, "https://api.soundcloud.com/tracks/" <> _rest = location} ->
            case HTTPoison.get(location) do
              {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
                body
                |> Poison.decode!
                |> create_track

              {:ok, %HTTPoison.Response{status_code: code}} ->
                {:error, "Could not retrieve the details: status code #{code}"}

              {:error, %HTTPoison.Error{reason: reason}} ->
                {:error, reason}
            end
          {_, location} ->
            {:error, "URL #{location} not supported (not a track?)"}
        end

      {:ok, %HTTPoison.Response{status_code: code}} ->
        {:error, "Could not retrieve the details: status code #{code}"}

      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end

  @spec match?(String.t) :: true|false
  def match?(url), do: Regex.match?(~r/^https?:\/\/(www.)?soundcloud\.com/, url)

  @spec create(String.t) :: {:ok, %RS.SoundcloudTrack{}}|{:error, String.t}
  def create(url) do
    case RS.SoundcloudTrack.soundcloud_info(url) do
      {:ok, %{protected: true}} -> {:error, "This video is protected with cipher signature"}
      {:ok, %{streams: []}} -> {:error, "Could not retrieve the download URL"}
      {:ok, %{streams: [stream_url|_rest], title: title, pictures: %{standard: picture_url}}} ->
        {:ok, %RS.SoundcloudTrack{url: url, stream_url: stream_url, title: title, picture_url: picture_url}}
      {:error, _} = error -> error
    end
  end

  defp create_track(body) do
    {:ok, %SoundcloudInfo{
      streams: [body["stream_url"]],
      protected: !body["streamable"],
      title: body["title"],
      duration: div(body["duration"], 1000),
      pictures: %{
        standard: body["artwork_url"],
        t300x300: String.replace(body["artwork_url"], "large", "t300x300"),
        t500x500: String.replace(body["artwork_url"], "large", "t500x500"),
      }
    }}
  end
end

defimpl RS.Playable, for: RS.SoundcloudTrack do
  @spec audio_stream!(%RS.SoundcloudTrack{}) :: Stream.t
  def audio_stream!(%RS.SoundcloudTrack{stream_url: stream_url}) do
    client_id = Application.fetch_env!(:rs, :soundcloud_client_id)
    %HTTPoison.Response{status_code: 302, headers: headers} = HTTPoison.get!(stream_url <> "?client_id=#{client_id}")
    {_, final_url} = Enum.find(headers, fn {k, _v} -> k == "Location" end)
    final_url
    |> RS.Downloader.stream!
    |> RS.AudioExtractor.extract!
  end
end
