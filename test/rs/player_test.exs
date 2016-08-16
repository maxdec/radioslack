defmodule RS.PlayerTest do
  use ExUnit.Case, async: true

  setup context do
    {:ok, streamer} = GenEvent.start_link(name: :"#{context.test}_streamer")
    {:ok, supervisor} = Task.Supervisor.start_link(name: :"#{context.test}_supervisor")
    {:ok, player} = RS.Player.start_link(:"#{context.test}_player", supervisor, streamer, :"#{context.test}_table")
    # add the Forwarder as a handler, pass the current pid (self) as the state
    GenEvent.add_handler(streamer, Forwarder, self)
    {:ok, %{player: player, supervisor: supervisor, streamer: streamer}}
  end

  describe "Playlist management features" do
    test "action {:add, url}", %{player: player} do
      action = {:add, "./samples/sample_audio_full.mp3", %{id: 123, name: "Max"}}
      assert RS.Player.action(player, action) |> String.contains?("New track enqueued")

      action = {:add, "./samples/does_not_exist.mp3", %{id: 123, name: "Max"}}
      assert RS.Player.action(player, action) |> String.contains?("Track not recognized or not supported: #{elem(action, 1)}")
    end

    test "action :status", %{player: player} do
      assert RS.Player.action(player, :status) |> String.contains?("The player is currently stopped")
    end

    test "action :playlist", %{player: player} do
      assert RS.Player.action(player, :playlist) |> String.contains?("The playlist is empty.")

      user = %{id: 123, name: "Max"}
      RS.Player.action(player, {:add, "./samples/sample_audio_full.mp3", user})
      RS.Player.action(player, {:add, "./samples/sample_audio_full.mp3", user})

      msg = "*Playlist:*"
      assert RS.Player.action(player, :playlist) |> String.contains?(msg)
    end

    test "actions :listeners_inc/:listeners_dec", %{player: player} do
      assert RS.Player.action(player, :listeners_inc) == "A listener has joined the stream"
      assert RS.Player.action(player, :get_state).listeners == 1
      RS.Player.action(player, :listeners_inc)
      assert RS.Player.action(player, :get_state).listeners == 2
      assert RS.Player.action(player, :listeners_dec) == "A listener has left the stream"
      assert RS.Player.action(player, :get_state).listeners == 1
      RS.Player.action(player, :listeners_dec)
      assert RS.Player.action(player, :get_state).listeners == 0
      RS.Player.action(player, :listeners_dec)
      RS.Player.action(player, :listeners_dec)
      assert RS.Player.action(player, :get_state).listeners == 0
    end
  end

  describe "Streaming features" do
    test "RS.Player allows to send chunks of data to listeners", %{streamer: streamer} do
      RS.Player.send(streamer, "chunk of data")
      RS.Player.send(streamer, "chunk of data")
      RS.Player.send(streamer, "chunk of data")

      assert_receive {:chunk, "chunk of data"}
      assert_receive {:chunk, "chunk of data"}
      assert_receive {:chunk, "chunk of data"}
    end
  end
end
