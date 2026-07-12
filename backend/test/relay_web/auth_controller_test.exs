defmodule RelayWeb.AuthControllerTest do
  use RelayWeb.ConnCase, async: true
  test "register and me", %{conn: conn} do
    conn = post(conn, "/api/auth/register", %{email: "api@example.com", username: "apiuser", password: "password123"})
    %{"data" => %{"token" => token, "user" => %{"id" => id}}} = json_response(conn, 201)
    conn = build_conn() |> put_req_header("authorization", "Bearer " <> token) |> get("/api/auth/me")
    assert %{"data" => %{"id" => ^id}} = json_response(conn, 200)
  end
end
