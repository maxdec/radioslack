defmodule RS.Utils do
  @spec slack_help() :: String.t
  def slack_help do
    """
    Help:
      /radio current
      /radio add $url
      /radio help
    """
  end

  @spec api_help() :: String.t
  def api_help do
    """
    Help
      GET /stream
      POST /api
      GET /help
    """
  end

  @spec wrong_method(Plug.Conn.t, String.t) :: Plug.Conn.t
  def wrong_method(%Plug.Conn{method: method} = conn, expected_method) do
    conn
    |> Plug.Conn.send_resp(404, "You are using the #{method} method but you need to use the #{expected_method} method.")
    |> Plug.Conn.halt
  end

  @doc """
  Returns (hh:)mm:ss for the given Time.

  ## Examples:

      iex> RS.Utils.format_duration(~T[10:00:05])
      "10:00:05"
      iex> RS.Utils.format_duration(~T[00:00:05])
      "00:05"

  """
  @spec format_duration(Time.t) :: String.t
  def format_duration(time) do
    time
    |> Time.to_string
    |> String.replace_prefix("00:", "")
  end

  @doc """
  Transforms a timestamp (integer) into a Time.
  :calendar.seconds_to_time only works for integer < 1 day = 24 * 3600 seconds.

  ## Examples:

      iex> RS.Utils.duration_to_time(123)
      ~T[00:02:03]
      iex> RS.Utils.duration_to_time(12345)
      ~T[03:25:45]

  """
  @spec duration_to_time(integer) :: Time.t
  def duration_to_time(duration) when duration < 24 * 3600 do
    duration
    |> :calendar.seconds_to_time
    |> Time.from_erl!
  end
end
