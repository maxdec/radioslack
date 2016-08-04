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
end
