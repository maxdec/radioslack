defmodule RS.Router do
  @behaviour Plug
  use RS.SimpleRouter

  unless Mix.env == :test do
    plug Plug.Logger
  end
  plug Plug.Parsers, parsers: [:urlencoded]

  ## STREAM
  def route "GET", "/stream", conn, opts do
    RS.StreamPlug.call(conn, opts)
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
end
