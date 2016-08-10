defmodule RS.StreamPlug do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, opts) do
    conn = send_chunked(conn, 200)
    |> put_resp_content_type("audio/mpeg")
    |> put_resp_header("transfer-encoding", "chunked")
    |> put_resp_header("expires", "-1")
    |> put_resp_header("pragma", "no-cache")
    |> put_resp_header("cache-control", "no-cache, no-store, must-revalidate")

    RS.Player.action(opts[:player], :listeners_inc)

    try do
      {_, conn} = RS.Player.stream(opts[:streamer])
      |> Enum.map_reduce(conn, &send_chunk/2)
      RS.Player.action(opts[:player], :listeners_dec)
      conn
    catch
      {:error, reason, conn} ->
        IO.puts("Error: #{reason}")
        RS.Player.action(opts[:player], :listeners_dec)
        conn
      error ->
        IO.inspect(error)
        RS.Player.action(opts[:player], :listeners_dec)
        conn
    end
  end

  defp send_chunk({:chunk, chk}, conn) do
    case chunk(conn, chk) do
      {:ok, conn} -> {:ok, conn}
      {:error, reason} -> throw {:error, reason, conn}
    end
  end
end
