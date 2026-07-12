defmodule RelayWeb.Serializer do
  def user(nil), do: nil
  def user(u), do: %{id: u.id, email: u.email, username: u.username, display_name: u.display_name, avatar_url: u.avatar_url}
  def conversation(c), do: %{id: c.id, kind: c.kind, name: c.name, last_message_at: c.last_message_at, members: if(Ecto.assoc_loaded?(c.memberships), do: Enum.map(c.memberships, &membership/1), else: [])}
  def membership(m), do: %{user: if(Ecto.assoc_loaded?(m.user), do: user(m.user), else: %{id: m.user_id}), role: m.role, banned_at: m.banned_at}
  def message(m), do: %{id: m.id, conversation_id: m.conversation_id, body: m.body, attachment: attachment(m), deleted_at: m.deleted_at, inserted_at: m.inserted_at, sender: if(Ecto.assoc_loaded?(m.sender), do: user(m.sender), else: %{id: m.sender_id})}
  def notification(n), do: %{id: n.id, type: n.type, data: n.data, read_at: n.read_at, inserted_at: n.inserted_at}
  def call(c), do: %{id: c.id, conversation_id: c.conversation_id, kind: c.kind, status: c.status, started_at: c.started_at, ended_at: c.ended_at, inserted_at: c.inserted_at, initiator: if(Ecto.assoc_loaded?(c.initiator), do: user(c.initiator), else: %{id: c.initiator_id}), participants: if(Ecto.assoc_loaded?(c.participants), do: Enum.map(c.participants, &%{user_id: &1.user_id, joined_at: &1.joined_at, left_at: &1.left_at}), else: [])}
  defp attachment(%{attachment_path: nil}), do: nil
  defp attachment(m), do: %{url: RelayWeb.Endpoint.url() <> "/uploads/#{m.attachment_path}", filename: m.attachment_name, content_type: m.attachment_type, size: m.attachment_size}
end
