defmodule RelayWeb.ModerationController do
  use RelayWeb, :controller
  alias Relay.{Chat, Guardian}
  def kick(conn, p), do: act(conn, p, :kick)
  def ban(conn, p), do: act(conn, p, :ban)
  defp act(conn, %{"conversation_id" => cid, "user_id" => target}, action) do with {:ok, _} <- Chat.moderate(cid, Guardian.Plug.current_resource(conn).id, action, target), do: json(conn, %{data: %{ok: true}}) end
end
