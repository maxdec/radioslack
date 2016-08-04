defmodule RS.ApiPlugTest do
  use ExUnit.Case, async: true
  use Plug.Test

  setup context do
    {:ok, player} = FakePlayerManager.start_link(context.test)
    {:ok, player: player, token: Application.fetch_env!(:rs, :slack_token)}
  end

  describe "ApiPlug handles actions given in the :text param, and return the result" do
    test "single-word actions", %{player: player, token: token} do
      for action <- ["start", "stop", "next", "status", "current", "playlist", "help"] do
        conn = conn(:post, "/", %{token: token, text: action})
        conn = RS.ApiPlug.call(conn, [player: player])

        assert conn.state == :sent
        assert conn.status == 200
        assert conn.resp_body != nil
      end
    end

    test "adding a track", %{player: player, token: token} do
      conn = conn(:post, "/", %{token: token, text: "add http://foo.bar"})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body != nil
    end
  end

  describe "ApiPlug returns 403 when the token is invalid" do
    test "the token is empty", %{player: player} do
      conn = conn(:post, "/", %{token: ""})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 403
      assert conn.resp_body == "Not authorized"
    end

    test "the token is incorrect", %{player: player} do
      conn = conn(:post, "/", %{token: "567"})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 403
      assert conn.resp_body == "Not authorized"
    end

    test "the token is correct", %{player: player, token: token} do
      conn = conn(:post, "/", %{token: token, text: "help"})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 200
      assert conn.resp_body != nil
    end
  end

  describe "ApiPlug returns 404 when the action is unknown" do
    test "the action is empty", %{player: player, token: token} do
      conn = conn(:post, "/", %{token: token})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "Command not recognized"
    end

    test "the action is unknown", %{player: player, token: token} do
      conn = conn(:post, "/", %{token: token, text: "FOO"})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "Command not recognized"
    end

    test "the action is :add but the syntax is incorrect", %{player: player, token: token} do
      conn = conn(:post, "/", %{token: token, text: "add bobby brown"})
      conn = RS.ApiPlug.call(conn, [player: player])

      assert conn.state == :sent
      assert conn.status == 404
      assert conn.resp_body == "Command not recognized"
    end
  end
end
