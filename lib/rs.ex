defmodule RS do
  use Application

  @names %{
    supervisor: RS.Supervisor,
    streamer: RS.Streamer,
    player: RS.Player,
    player_supervisor: RS.PlayerSupervisor,
    player_table: :player_table,
  }

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    hostname = Application.fetch_env!(:rs, :hostname)
    port = Application.fetch_env!(:rs, :port) |> String.to_integer

    children = [
      supervisor(Task.Supervisor, [[name: @names.player_supervisor]]),
      worker(RS.Player, [@names.player, @names.player_supervisor, @names.streamer, @names.player_table]),
      worker(GenEvent, [[name: @names.streamer]]),
      Plug.Adapters.Cowboy.child_spec(:http, RS.Router, [
        streamer: @names.streamer,
        player: @names.player,
        player_supervisor: @names.player_supervisor
      ], [port: port])
    ]

    if Mix.env != :test do
      IO.puts "The server is running at #{hostname}"
    end

    opts = [strategy: :one_for_one, name: @names.supervisor]
    Supervisor.start_link(children, opts)
  end
end
