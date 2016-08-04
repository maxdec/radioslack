defmodule RS.StreamPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup context do
    {:ok, streamer} = GenEvent.start_link(name: :"#{context.test}_streamer")
    {:ok, supervisor} = Task.Supervisor.start_link(name: :"#{context.test}_supervisor")
    {:ok, player} = RS.Player.start_link(:"#{context.test}_player", supervisor, streamer)
    {:ok, %{player: player, supervisor: supervisor, streamer: streamer}}
  end

  test "This Plug sends the events from the streamer to the connection as chunks", %{streamer: streamer, player: player} do
    spawn_link fn ->
      Process.sleep(100)
      RS.Player.send(streamer, "1")
      RS.Player.send(streamer, "2")
      RS.Player.send(streamer, "3")
      GenEvent.stop(streamer, :normal)
    end

    conn = conn(:get, "/")
    conn = RS.StreamPlug.call(conn, [streamer: streamer, player: player])

    assert conn.state == :chunked
    assert conn.status == 200
    assert conn.resp_body == "123"
  end
end
