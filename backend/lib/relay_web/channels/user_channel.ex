defmodule RelayWeb.UserChannel do
  use RelayWeb, :channel
  alias RelayWeb.Presence
  @impl true
  def join("user:" <> id, _payload, socket) when id == socket.assigns.current_user.id do
    send(self(), :after_join)
    {:ok, socket}
  end
  def join(_, _, _), do: {:error, %{reason: "forbidden"}}
  @impl true
  def handle_info(:after_join, socket) do
    {:ok, _} = Presence.track(socket, socket.assigns.current_user.id, %{online_at: System.system_time(:second), username: socket.assigns.current_user.username})
    push(socket, "presence_state", Presence.list(socket)); {:noreply, socket}
  end
end
