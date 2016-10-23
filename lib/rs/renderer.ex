defmodule RS.Renderer do

  @spec response([%{}]) :: String.t
  def response(attachments) do
    %{
      "text": "",
      "response_type": "ephemeral",
      "attachments": attachments
    } |> Poison.encode!
  end

  @spec status(atom, integer) :: %{}
  def status(status, listeners) do
    color = case status do
      :started -> "good"
      :stopped -> "warning"
    end

    %{
      color: color,
      pretext: "*Status:*",
      title: status |> to_string |> String.capitalize,
      text: "There are #{listeners} listeners\nListen <#{Application.fetch_env!(:rs, :hostname)}/stream|here>!",
      mrkdwn_in: ["pretext", "text"]
    }
  end

  @spec playlist([RS.Playable.t]) :: %{}
  def playlist(tracks) do
    {tracks, rest} = Enum.split(tracks, 10)
    case tracks do
      [] ->
        %{
          color: "warning",
          pretext: "*Playlist:*",
          title: "The playlist is empty.",
          mrkdwn_in: ["pretext"]
        }
      tracks ->
        tracks_json = tracks
        |> Enum.with_index
        |> Enum.map(fn {tr, i} ->
          pretext = case i do
            0 -> "*Playlist:*"
            _ -> ""
          end
          track(tr, pretext)
        end)

        rest_json = case rest do
          [] -> []
          rest ->
            [%{
              color: "green",
              text: "_And #{length(rest)} more_",
              mrkdwn_in: ["text"]
            }]
        end

        (tracks_json ++ rest_json)
    end
  end

  @spec help() :: %{}
  def help do
    text = Enum.join([
      "*/radio status* - displays the player status",
      "*/radio playlist* - displays the tracks in the playlist",
      "*/radio add <url>* - adds a new track to the playlist (YouTube or SoundCloud links)",
      "*/radio help* - displays the help",
    ], "\n")

    %{
      color: "#ccc",
      title: "Help",
      text: text,
      mrkdwn_in: ["text"]
    }
  end

  @spec warning(String.t) :: %{}
  def warning(message) do
    %{
      color: "warning",
      text: message
    }
  end

  @spec error(String.t) :: %{}
  def error(message) do
    %{
      color: "danger",
      title: "An error occured",
      text: message
    }
  end

  @spec track(RS.Playable.t, String.t) :: %{}
  def track(track, pretext) do
    footer = case track do
      %RS.SoundcloudTrack{} ->
        %{
          footer: "SoundCloud — #{RS.Utils.format_duration(track.duration)}",
          footer_icon: "https://a-v2.sndcdn.com/assets/images/sc-icons/ios-a62dfc8f.png"
        }
      %RS.YoutubeTrack{} ->
        %{
          footer: "YouTube — #{RS.Utils.format_duration(track.duration)}",
          footer_icon: "https://s.ytimg.com/yts/img/favicon_96-vfldSA3ca.png"
        }
      _ ->
        %{footer: "Other"}
    end

    %{
      color: "good",
      pretext: pretext,
      author_name: "Added by <@#{track.user.id}|#{track.user.name}>",
      title: track.title,
      title_link: track.url,
      thumb_url: track.picture_url,
      mrkdwn_in: ["pretext"]
    }
    |> Map.merge(footer)
  end
end
