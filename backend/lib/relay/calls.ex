defmodule Relay.Calls do
  import Ecto.Query
  alias Relay.{Repo, Chat, Calls.Call, Calls.Participant}
  def history(conversation_id, user_id) do
    if Chat.member?(conversation_id, user_id), do: {:ok, Repo.all(from c in Call, where: c.conversation_id == ^conversation_id, preload: [:initiator, participants: :user], order_by: [desc: c.inserted_at], limit: 50)}, else: {:error, :forbidden}
  end
  def start(conversation_id, user_id, kind \\ "voice") when kind in ["voice", "video"] do
    if Chat.member?(conversation_id, user_id) do
      Repo.transaction(fn ->
        {:ok, call} = %Call{} |> Call.changeset(%{conversation_id: conversation_id, initiator_id: user_id, status: :ringing, kind: kind}) |> Repo.insert()
        {:ok, _} = %Participant{} |> Participant.changeset(%{call_id: call.id, user_id: user_id, joined_at: DateTime.utc_now()}) |> Repo.insert()
        call
      end)
    else {:error, :forbidden} end
  end
  def start(_, _, _), do: {:error, :invalid_call_kind}
  def join(call_id, user_id) do
    with %Call{} = call <- Repo.get(Call, call_id), true <- Chat.member?(call.conversation_id, user_id) do
      Repo.insert(Participant.changeset(%Participant{}, %{call_id: call_id, user_id: user_id, joined_at: DateTime.utc_now()}), on_conflict: [set: [joined_at: DateTime.utc_now(), left_at: nil]], conflict_target: [:call_id, :user_id])
    else _ -> {:error, :forbidden} end
  end
  def leave(call_id, user_id) do
    case Repo.get_by(Participant, call_id: call_id, user_id: user_id) do nil -> {:error, :not_found}; p -> p |> Ecto.Changeset.change(left_at: DateTime.utc_now()) |> Repo.update() end
  end
  def end_call(call_id, user_id) do
    case Repo.get_by(Call, id: call_id, initiator_id: user_id) do nil -> {:error, :forbidden}; c -> c |> Call.changeset(%{status: :ended, ended_at: DateTime.utc_now()}) |> Repo.update() end
  end
end
