defmodule RS.ApiPlug do
  @behaviour Plug
  import Plug.Conn

  def init(opts), do: opts

  def call(%Plug.Conn{params: params} = conn, opts) do
    if params["token"] != Application.fetch_env!(:rs, :slack_token) do
      send_resp(conn, 403, "Not authorized")
    else
      case parse_action(params["text"] || "") do
        {:ok, :help} ->
          conn
          |> put_resp_content_type("application/json")
          |> send_resp(200, RS.Renderer.help)
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

  defp parse_action(cmd) do
    case String.split(cmd) do
      ["add", url] -> {:ok, {:add, url}}
      ["start"] -> {:ok, :start}
      ["stop"] -> {:ok, :stop}
      ["next"] -> {:ok, :next}
      ["status"] -> {:ok, :status}
      ["current"] -> {:ok, :current}
      ["playlist"] -> {:ok, :playlist}
      ["help"] -> {:ok, :help}
      _ -> {:error, :unknown_command}
    end
  end
end
