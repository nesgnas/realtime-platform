defmodule RelayWeb.NotificationController do
  use RelayWeb, :controller
  alias Relay.{Notifications, Guardian}; alias RelayWeb.Serializer
  def index(conn, _), do: json(conn, %{data: Enum.map(Notifications.list(uid(conn)), &Serializer.notification/1)})
  def read(conn, %{"id" => id}) do with {:ok, n} <- Notifications.mark_read(uid(conn), id), do: json(conn, %{data: Serializer.notification(n)}) end
  defp uid(conn), do: Guardian.Plug.current_resource(conn).id
end
