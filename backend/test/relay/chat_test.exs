defmodule Relay.ChatTest do
  use Relay.DataCase, async: true
  alias Relay.{Accounts, Chat}
  defp user(n), do: Accounts.register_user(%{email: "u#{n}@example.com", username: "user#{n}", password: "password123"}) |> elem(1)
  test "only members can read or send messages" do
    owner = user(1); member = user(2); outsider = user(3)
    assert {:ok, conversation} = Chat.create_group(owner.id, "Team", [member.id])
    assert {:ok, message} = Chat.create_message(conversation.id, member.id, %{body: "hello"})
    assert message.body == "hello"
    assert {:error, :forbidden} = Chat.list_messages(conversation.id, outsider.id)
    assert {:error, :forbidden} = Chat.create_message(conversation.id, outsider.id, %{body: "nope"})
  end
  test "direct conversations are idempotent" do
    a = user(4); b = user(5)
    assert {:ok, first} = Chat.create_direct(a.id, b.id)
    assert {:ok, second} = Chat.create_direct(a.id, b.id)
    assert first.id == second.id
  end
end
