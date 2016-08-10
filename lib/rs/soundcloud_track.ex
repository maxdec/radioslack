defmodule RS.SoundcloudTrack do
  @behaviour RS.Track

  defstruct [url: "", type: :soundcloud, title: "", stream_url: "", duration: ~T[00:00:00], picture_url: "", user: nil]

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
                |> create_info

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

  @spec create(String.t, %{}) :: {:ok, %RS.SoundcloudTrack{}}|{:error, String.t}
  def create(url, user) do
    case RS.SoundcloudTrack.soundcloud_info(url) do
      {:ok, %{protected: true}} -> {:error, "This video is protected with cipher signature"}
      {:ok, %{streams: []}} -> {:error, "Could not retrieve the download URL"}
      {:ok, info} -> {:ok, create_track(info, url, user)}
      {:error, _} = error -> error
    end
  end

  @spec create_info(%{}) :: %SoundcloudInfo{}
  defp create_info(body) do
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

  @spec create_track(%SoundcloudInfo{}, String.t, %{}) :: %RS.SoundcloudTrack{}
  defp create_track(%SoundcloudInfo{} = info, url, user) do
    %RS.SoundcloudTrack{
      url: url,
      stream_url: List.first(info.streams),
      title: info.title,
      picture_url: info.pictures.standard,
      duration: RS.Utils.duration_to_time(info.duration),
      user: user
    }
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
