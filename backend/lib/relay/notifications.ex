defmodule Relay.Notifications do
  import Ecto.Query
  alias Relay.{Repo, Notifications.Notification}
  def create(user_id, type, data \\ %{}) do
    with {:ok, notification} <- %Notification{} |> Notification.changeset(%{user_id: user_id, type: type, data: data}) |> Repo.insert() do
      RelayWeb.Endpoint.broadcast("user:#{user_id}", "notification", RelayWeb.Serializer.notification(notification))
      {:ok, notification}
    end
  end
  def list(user_id), do: Repo.all(from n in Notification, where: n.user_id == ^user_id, order_by: [desc: n.inserted_at], limit: 100)
  def mark_read(user_id, id) do
    case Repo.get_by(Notification, id: id, user_id: user_id) do
      nil -> {:error, :not_found}
      row -> row |> Ecto.Changeset.change(read_at: DateTime.utc_now()) |> Repo.update()
    end
  end
end
