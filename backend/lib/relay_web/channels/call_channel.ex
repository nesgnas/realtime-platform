defmodule RelayWeb.CallChannel do
  use RelayWeb, :channel
  alias Relay.{Calls, Repo, Calls.Call, Chat}
  @impl true
  def join("call:" <> call_id, _payload, socket) do
    with %Call{} = call <- Repo.get(Call, call_id), true <- Chat.member?(call.conversation_id, socket.assigns.current_user.id), {:ok, _} <- Calls.join(call_id, socket.assigns.current_user.id) do
      send(self(), :announce_join); {:ok, assign(socket, :call_id, call_id)}
    else _ -> {:error, %{reason: "forbidden"}} end
  end
  @impl true
  def handle_info(:announce_join, socket) do broadcast_from!(socket, "participant:joined", %{user_id: uid(socket)}); {:noreply, socket} end
  @impl true
  def handle_in("signal", payload, socket) do
    broadcast_from!(socket, "signal", Map.put(payload, "from", uid(socket)))
    {:reply, :ok, socket}
  end
  def handle_in("call:end", _, socket) do case Calls.end_call(socket.assigns.call_id, uid(socket)) do {:ok, _} -> broadcast!(socket, "call:ended", %{by: uid(socket)}); {:reply, :ok, socket}; {:error, _} -> {:reply, {:error, %{reason: "forbidden"}}, socket} end end
  @impl true
  def terminate(_reason, socket) do Calls.leave(socket.assigns.call_id, uid(socket)); :ok end
  defp uid(socket), do: socket.assigns.current_user.id
end
