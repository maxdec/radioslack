defmodule RS.Player do
  use GenServer

  ##############
  # Client API #
  ##############

  @doc """
  Starts the Player.
  """
  def start_link(name, supervisor, streamer) do
    GenServer.start_link(__MODULE__, [supervisor: supervisor, streamer: streamer], name: name)
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
  def action(name, action), do: GenServer.call(name, action)

  ####################
  # Server Callbacks #
  ####################

  defmodule State do
    defstruct status: :stopped,
              playlist: [], # [%Track{}, ...]
              current: nil,
              player_pid: nil,
              supervisor: nil,
              streamer: nil,
              listeners: 0,
              next_votes: 0 # TODO
  end

  def init(opts) do
    {:ok, struct(State, opts)}
  end

  def handle_call(:status, _from, state) do
    {:reply, format_status(state), state}
  end

  def handle_call(:current, _from, %{current: nil} = state) do
    {:reply, RS.Renderer.warning("No track playing"), state}
  end
  def handle_call(:current, _from, %{current: current} = state) do
    {:reply, RS.Renderer.track(current, "Current track"), state}
  end

  def handle_call(:playlist, _from, %{playlist: playlist} = state) do
    {:reply, RS.Renderer.playlist(playlist), state}
  end

  def handle_call({:add, url}, _from, state) do
    case RS.TrackBuilder.create(url) do
      {:ok, track} ->
        state = Map.update!(state, :playlist, &(&1 ++ [track]))
        {:reply, RS.Renderer.track(track, "New track enqueued"), state}
      {:error, reason} ->
        {:reply, RS.Renderer.error("#{reason}: #{url}"), state}
    end
  end

  def handle_call(:start, _from, %{status: status, current: current} = state) do
    case status do
      :started -> {:reply, RS.Renderer.warning("Already started"), state}
      :stopped ->
        case current do
          nil ->
            state = play_next(state)
            case state.status do
              :started -> {:reply, RS.Renderer.track(state.current, "Playing"), state}
              :stopped -> {:reply, RS.Renderer.warning("No track available"), state}
            end
          track ->
            {:ok, pid} = start_playback(state.supervisor, track, state.streamer)
            state = state
            |> Map.put(:status, :started)
            |> Map.put(:player_pid, pid)
            {:reply, RS.Renderer.track(track, "Playing"), state}
        end
    end
  end

  def handle_call(:stop, _from, %{status: :stopped} = state) do
    {:reply, "Already stopped", state}
  end
  def handle_call(:stop, _from, %{supervisor: supervisor, player_pid: player_pid} = state) do
    stop_playback(supervisor, player_pid)
    state = state
    |> Map.put(:status, :stopped)
    |> Map.put(:player_pid, nil)
    {:reply, RS.Renderer.warning("Player stopped"), state}
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

  def handle_info({ref, result}, state) do
    IO.puts("Task #{inspect ref} finished: #{result} -> should do `next`")
    {:noreply, play_next(state)}
  end

  def handle_info({:DOWN, ref, :process, _pid, _reason}, state) do
    IO.puts("DOWN: #{inspect ref}")
    {:noreply, Map.put(state, :player_pid, nil)}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end

  ##################
  # Player actions #
  ##################

  @spec play_next(%State{}) :: %State{}
  def play_next(%{playlist: playlist} = state) do
    if List.first(playlist) do
      [track|playlist] = playlist
      pid = start_playback(state.supervisor, track, state.streamer)
      state
      |> Map.put(:status, :started)
      |> Map.put(:playlist, playlist)
      |> Map.put(:current, track)
      |> Map.put(:player_pid, pid)
    else
      state
      |> Map.put(:status, :stopped)
      |> Map.put(:current, nil)
      |> Map.put(:player_pid, nil)
    end
  end

  def start_playback(supervisor, track, streamer) do
    %Task{pid: pid} = Task.Supervisor.async(supervisor, fn -> play_stream(streamer, track) end)
    pid
  end

  def stop_playback(supervisor, task_ref) do
    Task.Supervisor.terminate_child(supervisor, task_ref)
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
  defp format_status(%{status: status, listeners: listeners, current: current}) do
    case status do
      :stopped -> RS.Renderer.warning("The player is currently stopped")
      :started -> RS.Renderer.status(current, listeners)
    end
  end
end
