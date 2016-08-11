defmodule RS do
  use Application

  @names %{
    supervisor: RS.Supervisor,
    streamer: RS.Streamer,
    player: RS.Player,
    player_supervisor: RS.PlayerSupervisor
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    hostname = Application.fetch_env!(:rs, :hostname)
    port = Application.fetch_env!(:rs, :port) |> String.to_integer

    children = [
      supervisor(Task.Supervisor, [[name: @names.player_supervisor]]),
      worker(RS.Player, [@names.player, @names.player_supervisor, @names.streamer]),
      worker(GenEvent, [[name: @names.streamer]]),
      Plug.Adapters.Cowboy.child_spec(:http, RS.Router, [
        streamer: @names.streamer,
        player: @names.player,
        player_supervisor: @names.player_supervisor
      ], [port: port])
    ]

    IO.puts "The server is running at #{hostname}"

    opts = [strategy: :one_for_one, name: @names.supervisor]
    Supervisor.start_link(children, opts)
  end
end
