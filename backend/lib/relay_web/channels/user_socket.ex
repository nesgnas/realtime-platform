defmodule RelayWeb.UserSocket do
  use Phoenix.Socket
  channel "user:*", RelayWeb.UserChannel
  channel "conversation:*", RelayWeb.ConversationChannel
  channel "call:*", RelayWeb.CallChannel

  @impl true
  def connect(%{"token" => token}, socket, _info) do
    case Relay.Guardian.decode_and_verify(token) do
      {:ok, claims} -> case Relay.Guardian.resource_from_claims(claims) do {:ok, user} -> {:ok, assign(socket, :current_user, user)}; _ -> :error end
      _ -> :error
    end
  end
  def connect(_, _, _), do: :error
  @impl true
  def id(socket), do: "socket:#{socket.assigns.current_user.id}"
end
