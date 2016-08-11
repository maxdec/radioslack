defmodule RS.Router do
  @behaviour Plug
  use RS.SimpleRouter

  unless Mix.env == :test do
    plug Plug.Logger
  end
  plug Plug.Parsers, parsers: [:urlencoded]

  ## STREAM
  def route "GET", "/stream", conn, opts do
    if conn |> get_req_header("accept") |> accepts_http do
      conn
      |> put_resp_header("expires", "-1")
      |> put_resp_header("pragma", "no-cache")
      |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")
      |> send_file(200, "priv/static/player.html")
    else
      RS.StreamPlug.call(conn, opts)
    end
  end
  def route "POST", "/stream", conn, opts do
    RS.Player.send(opts[:streamer], "STREAMING...\n")
    send_resp(conn, 200, "SENT")
  end
  def route _, "/stream", conn, _opts do
    RS.Utils.wrong_method(conn, "GET")
  end

  ## API
  def route "POST", "/api", conn, opts do
    RS.ApiPlug.call(conn, opts)
  end
  def route _, "/api", conn, _opts do
    RS.Utils.wrong_method(conn, "POST")
  end

  ## HOME and HELP
  def route "GET", "/", conn, _opts do
    send_resp(conn, 200, "It's running!")
  end
  def route "GET", "/help", conn, _opts do
    send_resp(conn, 200, RS.Utils.api_help)
  end
  def route "GET", "/player", conn, _opts do
    send_file(conn, 200, "priv/static/player.html")
  end
  def route "GET", "/favicon.png", conn, _opts do
    send_file(conn, 200, "priv/static/favicon.png")
  end

  def route _, _, conn, _opts do
    send_resp(conn, 404, RS.Utils.api_help)
  end

  defp accepts_http([]), do: false
  defp accepts_http([first|_]), do: String.contains?(first, "text/html")
end
