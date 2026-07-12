defmodule RelayWeb.ConnCase do
  use ExUnit.CaseTemplate
  using do quote do @endpoint RelayWeb.Endpoint; use RelayWeb, :verified_routes; import Plug.Conn; import Phoenix.ConnTest; import RelayWeb.ConnCase end end
  setup tags do
    pid = Ecto.Adapters.SQL.Sandbox.start_owner!(Relay.Repo, shared: not tags[:async]); on_exit(fn -> Ecto.Adapters.SQL.Sandbox.stop_owner(pid) end); {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
  def register_user(attrs \\ %{}) do
    Relay.Accounts.register_user(Map.merge(%{email: "user#{System.unique_integer([:positive])}@example.com", username: "user#{System.unique_integer([:positive])}", password: "password123"}, attrs))
  end
  def authenticate(conn, user) do {:ok, token, _} = Relay.Guardian.encode_and_sign(user); Plug.Conn.put_req_header(conn, "authorization", "Bearer " <> token) end
end
