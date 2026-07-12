defmodule RelayWeb.CallController do
  use RelayWeb, :controller
  alias Relay.{Calls, Guardian}; alias RelayWeb.Serializer
  def index(conn, %{"conversation_id" => cid}) do with {:ok, rows} <- Calls.history(cid, Guardian.Plug.current_resource(conn).id), do: json(conn, %{data: Enum.map(rows, &Serializer.call/1)}) end
  def create(conn, %{"conversation_id" => cid} = params) do
    with {:ok, call} <- Calls.start(cid, uid(conn), params["kind"] || "voice") do
      call = Relay.Repo.preload(call, [:initiator, participants: :user])
      payload = Serializer.call(call)
      RelayWeb.Endpoint.broadcast("conversation:#{cid}", "call:started", payload)
      Relay.Chat.active_member_ids(cid)
      |> Enum.reject(&(&1 == uid(conn)))
      |> Enum.each(&RelayWeb.Endpoint.broadcast("user:#{&1}", "call_invite", payload))
      conn |> put_status(:created) |> json(%{data: payload})
    end
  end
  def end_call(conn, %{"id" => id}) do
    with {:ok, call} <- Calls.end_call(id, uid(conn)) do
      RelayWeb.Endpoint.broadcast("call:#{id}", "call:ended", %{by: uid(conn)})
      json(conn, %{data: Serializer.call(Relay.Repo.preload(call, [:initiator, participants: :user]))})
    end
  end
  defp uid(conn), do: Guardian.Plug.current_resource(conn).id
end
