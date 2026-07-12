defmodule Relay.Chat do
  import Ecto.Query
  alias Ecto.Multi
  alias Relay.{Repo, Chat.Conversation, Chat.Membership, Chat.Message, Notifications}

  def list_conversations(user_id) do
    Repo.all(from c in Conversation, join: m in Membership, on: m.conversation_id == c.id, where: m.user_id == ^user_id and is_nil(m.banned_at), preload: [memberships: :user], order_by: [desc_nulls_last: c.last_message_at, desc: c.inserted_at])
  end
  def member?(conversation_id, user_id), do: Repo.exists?(active_membership(conversation_id, user_id))
  def active_member_ids(conversation_id), do: Repo.all(from m in Membership, where: m.conversation_id == ^conversation_id and is_nil(m.banned_at), select: m.user_id)
  def active_membership(conversation_id, user_id), do: from(m in Membership, where: m.conversation_id == ^conversation_id and m.user_id == ^user_id and is_nil(m.banned_at))

  def create_direct(user_id, other_id) do
    key = Enum.sort([user_id, other_id]) |> Enum.join(":")
    case Repo.get_by(Conversation, direct_key: key) do
      %Conversation{} = row -> if member?(row.id, user_id), do: {:ok, Repo.preload(row, memberships: :user)}, else: {:error, :forbidden}
      nil -> create_conversation(%{kind: :direct, created_by_id: user_id, direct_key: key}, [user_id, other_id])
    end
  end
  def create_group(user_id, name, member_ids), do: create_conversation(%{kind: :group, name: name, created_by_id: user_id}, Enum.uniq([user_id | member_ids]))
  defp create_conversation(attrs, member_ids) do
    Multi.new() |> Multi.insert(:conversation, Conversation.changeset(%Conversation{}, attrs)) |> Multi.run(:memberships, fn repo, %{conversation: c} ->
      Enum.reduce_while(member_ids, {:ok, []}, fn id, {:ok, rows} ->
        role = if id == attrs.created_by_id, do: :owner, else: :member
        case repo.insert(Membership.changeset(%Membership{}, %{conversation_id: c.id, user_id: id, role: role})) do {:ok, row} -> {:cont, {:ok, [row | rows]}}; {:error, e} -> {:halt, {:error, e}} end
      end)
    end) |> Repo.transaction() |> case do {:ok, %{conversation: c}} -> {:ok, Repo.preload(c, memberships: :user)}; {:error, _, reason, _} -> {:error, reason} end
  end

  def list_messages(conversation_id, user_id, before_id \\ nil) do
    if member?(conversation_id, user_id) do
      base = from m in Message, where: m.conversation_id == ^conversation_id, preload: [:sender], order_by: [desc: m.inserted_at], limit: 50
      query = if before_id, do: from(m in base, where: m.inserted_at < subquery(from x in Message, where: x.id == ^before_id, select: x.inserted_at)), else: base
      {:ok, Repo.all(query)}
    else
      {:error, :forbidden}
    end
  end

  def create_message(conversation_id, user_id, attrs) do
    if member?(conversation_id, user_id) do
      attrs = attrs |> Map.new(fn {k, v} -> {to_string(k), v} end) |> Map.merge(%{"conversation_id" => conversation_id, "sender_id" => user_id})
      Multi.new() |> Multi.insert(:message, Message.changeset(%Message{}, attrs)) |> Multi.update_all(:touch, from(c in Conversation, where: c.id == ^conversation_id), set: [last_message_at: DateTime.utc_now()]) |> Repo.transaction() |> case do
        {:ok, %{message: message}} ->
          message = Repo.preload(message, :sender); payload = RelayWeb.Serializer.message(message)
          RelayWeb.Endpoint.broadcast("conversation:#{conversation_id}", "message:new", payload)
          notify_other_members(conversation_id, user_id, message.id); {:ok, message}
        {:error, _, reason, _} -> {:error, reason}
      end
    else
      {:error, :forbidden}
    end
  end

  def moderate(conversation_id, actor_id, action, target_id) do
    with %Membership{role: role} when role in [:owner, :admin] <- Repo.one(active_membership(conversation_id, actor_id)),
         %Membership{} = target <- Repo.get_by(Membership, conversation_id: conversation_id, user_id: target_id),
         true <- role == :owner or target.role == :member do
      case action do
        :kick -> Repo.delete(target)
        :ban -> target |> Ecto.Changeset.change(banned_at: DateTime.utc_now()) |> Repo.update()
      end
    else _ -> {:error, :forbidden} end
  end

  def delete_message(conversation_id, actor_id, message_id) do
    with %Message{} = message <- Repo.get_by(Message, id: message_id, conversation_id: conversation_id),
         true <- message.sender_id == actor_id or admin?(conversation_id, actor_id) do
      result = message |> Ecto.Changeset.change(body: nil, attachment_path: nil, attachment_name: nil, attachment_type: nil, attachment_size: nil, deleted_at: DateTime.utc_now()) |> Repo.update()
      if match?({:ok, _}, result), do: RelayWeb.Endpoint.broadcast("conversation:#{conversation_id}", "message:deleted", %{id: message_id})
      result
    else _ -> {:error, :forbidden} end
  end
  def admin?(cid, uid), do: Repo.exists?(from m in active_membership(cid, uid), where: m.role in [:owner, :admin])
  defp notify_other_members(cid, sender, message_id) do
    Repo.all(from m in Membership, where: m.conversation_id == ^cid and m.user_id != ^sender and is_nil(m.banned_at), select: m.user_id)
    |> Enum.each(&Notifications.create(&1, "message", %{conversation_id: cid, message_id: message_id, sender_id: sender}))
  end
end
