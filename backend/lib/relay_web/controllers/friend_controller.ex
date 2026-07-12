defmodule RelayWeb.FriendController do
  use RelayWeb, :controller
  alias Relay.{Accounts, Guardian}
  alias RelayWeb.Serializer
  def index(conn, _), do: json(conn, %{data: Enum.map(Accounts.list_friends(uid(conn)), &Serializer.user/1)})
  def requests(conn, _), do: json(conn, %{data: Enum.map(Accounts.list_requests(uid(conn)), &%{id: &1.id, sender: Serializer.user(&1.sender), status: &1.status, inserted_at: &1.inserted_at})})
  def create(conn, %{"recipient_id" => id}) do with {:ok, request} <- Accounts.send_friend_request(uid(conn), id), do: conn |> put_status(:created) |> json(%{data: %{id: request.id, status: request.status}}) end
  def create(conn, %{"username" => username}) do
    with %{} = user <- Accounts.get_user_by_username(username), {:ok, request} <- Accounts.send_friend_request(uid(conn), user.id) do
      conn |> put_status(:created) |> json(%{data: %{id: request.id, status: request.status}})
    else nil -> {:error, :not_found}; error -> error end
  end
  def update(conn, %{"id" => id, "status" => status}) when status in ["accepted", "declined"] do with {:ok, row} <- Accounts.respond_to_request(uid(conn), id, String.to_existing_atom(status)), do: json(conn, %{data: %{id: row.id, status: row.status}}) end
  defp uid(conn), do: Guardian.Plug.current_resource(conn).id
end
