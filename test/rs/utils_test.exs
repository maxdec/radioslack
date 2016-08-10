defmodule RS.UtilsTest do
  use ExUnit.Case, async: true
  use Plug.Test
  doctest RS.Utils

  test "wrong_method/2 returns 404" do
    conn = conn(:get, "/")
    conn = RS.Utils.wrong_method(conn, "POST")

    assert conn.state == :sent
    assert conn.status == 404
    assert conn.resp_body == "You are using the GET method but you need to use the POST method."
  end
end
