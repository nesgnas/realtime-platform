defmodule RelayWeb.ConversationController do
  use RelayWeb, :controller
  alias Relay.{Chat, Guardian}; alias RelayWeb.Serializer
  def index(conn, _), do: json(conn, %{data: Enum.map(Chat.list_conversations(uid(conn)), &Serializer.conversation/1)})
  def direct(conn, %{"user_id" => id}) do with {:ok, c} <- Chat.create_direct(uid(conn), id), do: conn |> put_status(:created) |> json(%{data: Serializer.conversation(c)}) end
  def group(conn, %{"name" => name, "member_ids" => ids}) do with {:ok, c} <- Chat.create_group(uid(conn), name, ids), do: conn |> put_status(:created) |> json(%{data: Serializer.conversation(c)}) end
  defp uid(conn), do: Guardian.Plug.current_resource(conn).id
end
