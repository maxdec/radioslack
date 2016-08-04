defmodule RS.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup context do
    {:ok, player} = FakePlayerManager.start_link(context.test)
    {:ok, player: player, token: Application.fetch_env!(:rs, :slack_token)}
  end

  describe "Endpoint /api" do
    test "POST /api", %{player: player, token: token} do
      conn = conn(:post, "/api", "text=start&token=#{token}")
      |> put_req_header("content-type", "application/x-www-form-urlencoded")

      conn = RS.Router.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body != nil
    end

    test "GET /api", %{player: player} do
      conn = conn(:get, "/api")
      conn = RS.Router.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body != nil
    end
  end
end
