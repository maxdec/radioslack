ExUnit.start()

defmodule FakePlayerManager do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, :ok, name: name)
  end

  def action(name, action), do: GenServer.call(name, action)

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call(action, _from, state) do
    case action do
      :start -> {:reply, "Playing: New Track", state}
      :stop -> {:reply, "Player stopped", state}
      :next -> {:reply, "Next track", state}
      :status -> {:reply, "The player is currently started", state}
      :current -> {:reply, "Current track: Foo - Bar", state}
      :playlist -> {:reply, "Playlist: ...", state}
      {:add, track} -> {:reply, "New track enqueued: #{track}", state}
    end
  end
end

defmodule Forwarder do
  use GenEvent

  # handle all events, first parameter is the event, second if the state
  def handle_event(event, test_pid) do
    # send the event to `test_pid`
    send(test_pid, event)

    # respond `:ok` and keep the same state (the test's pid)
    {:ok, test_pid}
  end
end
