defmodule RS.ApiPlug do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{params: params} = conn, opts) do
    if params["token"] != Application.fetch_env!(:rs, :slack_token) do
      send_resp(conn, 403, "Not authorized")
    else
      user = %{id: params["user_id"], name: params["user_name"]}
      case parse_action(params["text"] || "", user) do
        {:ok, :help} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, RS.Renderer.help |> Poison.encode!)
        {:ok, action} ->
          result = RS.Player.action(opts[:player], action)
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, result)
        {:error, :unknown_command} ->
          send_resp(conn, 404, "Command not recognized")
      end
    end
  end

  defp parse_action(cmd, user) do
    case String.split(cmd) do
      ["add", url] -> {:ok, {:add, url, user}}
      ["start"] -> {:ok, :start}
      ["stop"] -> {:ok, :stop}
      ["next"] -> {:ok, :next}
      ["status"] -> {:ok, :status}
      ["current"] -> {:ok, :current}
      ["playlist"] -> {:ok, :playlist}
      ["help"] -> {:ok, :help}
      [""] -> {:ok, :status}
      _ -> {:error, :unknown_command}
    end
  end
end
