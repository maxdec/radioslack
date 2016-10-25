defmodule RS.Player do
  use GenServer

  ##############
  # Client API #
  ##############

  @doc """
  Starts the Player.
  """
  def start_link(name, supervisor, streamer, table) do
    GenServer.start_link(__MODULE__, [
      supervisor: supervisor,
      streamer: streamer,
      player_table: table
    ], name: name)
  end

  @doc """
  actions:
    {:add, url} - Adds a track to the playlist.
    :start - Starts the player.
    :stop - Stops the player.
    :next - Skips the current track, plays the next one if available.
    :status - Looks up the current status of the Player.
    :current - Returns the current track.
    :playlist - Returns the playlist.
    :listeners_inc - INTERNAL - Increases the listeners count.
    :listeners_dec - INTERNAL - Decreases the listeners count.
    :get_state - INTERNAL - Returns the current state
  """
  def action(name, action) do
    try do
      GenServer.call(name, action)
    catch
      :exit, _ -> reply({:error, ["Something went wrong"]})
    end
  end

  ####################
  # Server Callbacks #
  ####################

  defmodule State do
    defstruct status: :stopped,
              playlist: [], # [%Track{}, ...]
              current: nil,
              supervisor: nil,
              streamer: nil,
              player_table: nil,
              listeners: 0,
              next_votes: 0 # TODO
  end

  def init(opts) do
    player_table = opts[:player_table]
    RS.Persistor.init(player_table)
    player_pid = Task.Supervisor.children(opts[:supervisor]) |> List.first

    {:ok, %State{
      supervisor: opts[:supervisor],
      streamer: opts[:streamer],
      player_table: player_table,
      current: RS.Persistor.get(player_table, :current),
      playlist: RS.Persistor.get(player_table, :playlist) || [],
      status: (if player_pid, do: :started, else: :stopped)
    }}
  end

  def handle_call(:status, _from, state) do
    {:reply, format_status(state), state}
  end

  def handle_call(:current, _from, %{current: nil} = state) do
    {:reply, reply({:warning, ["No track playing"]}), state}
  end
  def handle_call(:current, _from, %{current: current} = state) do
    {:reply, reply({:track, [current, "*Current track:*"]}), state}
  end

  def handle_call(:playlist, _from, %{playlist: playlist} = state) do
    {:reply, reply({:playlist, [playlist]}), state}
  end

  def handle_call({:add, url, user}, from, state) do
    case RS.TrackBuilder.create(url, user) do
      {:ok, track} ->
        state = Map.update!(state, :playlist, &(&1 ++ [track]))
        RS.Persistor.set(state.player_table, :playlist, state.playlist)

        case state.status do
          :started ->
            {:reply, reply({:track, [track, "*New track enqueued:*"]}), state}
          :stopped ->
            handle_call(:start, from, state)
        end
      {:error, reason} ->
        {:reply, reply({:warning, ["#{reason}: #{url}"]}), state}
    end
  end

  def handle_call(:start, _from, %{status: status, current: current} = state) do
    case status do
      :started -> {:reply, reply({:warning, ["Already started"]}), state}
      :stopped ->
        case current do
          nil ->
            state = play_next(state)
            case state.status do
              :started -> {:reply, reply({:track, [state.current, "*Playing:*"]}), state}
              :stopped -> {:reply, reply({:warning, ["No track available"]}), state}
            end
          track ->
            start_playback(state.supervisor, track, state.streamer)
            state = Map.put(state, :status, :started)
            {:reply, reply({:track, [track, "*Playing:*"]}), state}
        end
    end
  end

  def handle_call(:stop, _from, %{status: :stopped} = state) do
    {:reply, reply({:warning, ["Already stopped"]}), state}
  end
  def handle_call(:stop, _from, %{supervisor: supervisor} = state) do
    stop_playback(supervisor)
    state = Map.put(state, :status, :stopped)
    {:reply, reply({:warning, ["Player stopped"]}), state}
  end

  def handle_call(:next, from, %{status: :stopped} = state) do
    handle_call(:start, from, state)
  end
  def handle_call(:next, _from, %{supervisor: supervisor} = state) do
    state = play_next(state)
    case state.status do
      :started -> {:reply, reply({:track, [state.current, "*Playing:*"]}), state}
      :stopped -> {:reply, reply({:warning, ["No track available"]}), state}
    end
  end

  def handle_call(:listeners_inc, _from, state) do
    {:reply, "A listener has joined the stream", Map.put(state, :listeners, state.listeners + 1)}
  end

  def handle_call(:listeners_dec, _from, state) do
    {:reply, "A listener has left the stream", Map.put(state, :listeners, max(state.listeners - 1, 0))}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(action, _from, state) do
    {:reply, reply({:warning, ["The action `#{action}` is invalid."]}), state}
  end

  def handle_info({ref, result}, state) do
    IO.puts("Task #{inspect ref} finished: #{result} -> should do `next`")
    {:noreply, play_next(state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    IO.puts("DOWN: #{inspect ref}")
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ##################
  # Player actions #
  ##################

  @spec play_next(%State{}) :: %State{}
  def play_next(%{playlist: playlist} = state) do
    state = if List.first(playlist) do
      [track|playlist] = playlist
      start_playback(state.supervisor, track, state.streamer)
      state = state
      |> Map.put(:status, :started)
      |> Map.put(:playlist, playlist)
      |> Map.put(:current, track)
      RS.Persistor.set(state.player_table, :playlist, state.playlist)
      state
    else
      stop_playback(state.supervisor)
      state
      |> Map.put(:status, :stopped)
      |> Map.put(:current, nil)
    end
    RS.Persistor.set(state.player_table, :current, state.current)
    state
  end

  def start_playback(supervisor, track, streamer) do
    # Make sure we don't stop any existing track before playing a new one.
    stop_playback(supervisor)
    %Task{pid: pid} = Task.Supervisor.async_nolink(supervisor, fn -> play_stream(streamer, track) end)
    pid
  end

  def stop_playback(supervisor) do
    Task.Supervisor.children(supervisor)
    |> Enum.each(fn pid -> Task.Supervisor.terminate_child(supervisor, pid) end)
  end

  def play_stream(streamer, track) do
    RS.Playable.audio_stream!(track)
    |> Stream.each(fn chunk -> RS.Player.send(streamer, chunk) end)
    |> Stream.run
  end

  @doc """
  Notifies the event manager with an event of the form {:chunk, chunk}
  """
  def send(name, chunk), do: GenEvent.sync_notify(name, {:chunk, chunk})

  @doc """
  Returns the stream of events
  """
  def stream(name), do: GenEvent.stream(name)

  @spec format_status(%State{}) :: String.t
  defp format_status(%{status: status, listeners: listeners, current: current, playlist: playlist}) do
    case status do
      :stopped -> reply({:warning, ["The player is currently stopped"]})
      :started -> reply([
        {:status, [status, listeners]},
        {:track, [current, "*Currently Playing:*"]},
        {:playlist, [playlist]},
      ])
    end
  end

  defp reply({attachment, args}) do
    [apply(RS.Renderer, attachment, args)] |> RS.Renderer.response
  end

  defp reply(attachments) when is_list(attachments) do
    attachments
    |> Enum.map(fn {attachment, args} ->
      apply(RS.Renderer, attachment, args)
    end)
    |> RS.Renderer.response
  end
end
