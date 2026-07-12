defmodule RelayWeb.ConversationChannel do
  use RelayWeb, :channel
  alias Relay.{Chat, Calls}
  alias RelayWeb.Serializer
  @impl true
  def join("conversation:" <> cid, _payload, socket) do
    if Chat.member?(cid, socket.assigns.current_user.id), do: {:ok, assign(socket, :conversation_id, cid)}, else: {:error, %{reason: "forbidden"}}
  end
  @impl true
  def handle_in("message:new", attrs, socket) do
    case Chat.create_message(socket.assigns.conversation_id, uid(socket), Map.take(attrs, ["body"])) do {:ok, m} -> {:reply, {:ok, Serializer.message(m)}, socket}; {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket} end
  end
  def handle_in("typing", %{"typing" => typing}, socket) do broadcast_from!(socket, "typing", %{user_id: uid(socket), typing: typing}); {:noreply, socket} end
  def handle_in("call:start", _, socket) do
    case Calls.start(socket.assigns.conversation_id, uid(socket)) do {:ok, call} -> payload = Relay.Repo.preload(call, [:initiator, participants: :user]) |> Serializer.call(); broadcast!(socket, "call:started", payload); {:reply, {:ok, payload}, socket}; {:error, reason} -> {:reply, {:error, %{reason: inspect(reason)}}, socket} end
  end
  defp uid(socket), do: socket.assigns.current_user.id
end
