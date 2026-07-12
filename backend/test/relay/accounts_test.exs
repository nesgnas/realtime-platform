defmodule Relay.AccountsTest do
  use Relay.DataCase, async: true
  alias Relay.Accounts
  test "registers and authenticates a user" do
    attrs = %{email: "TEST@example.com", username: "tester", password: "password123"}
    assert {:ok, user} = Accounts.register_user(attrs)
    assert user.email == "test@example.com"
    assert {:ok, authenticated} = Accounts.authenticate("test@example.com", "password123")
    assert authenticated.id == user.id
    assert {:error, :invalid_credentials} = Accounts.authenticate("test@example.com", "wrong")
  end
  test "a user cannot friend themselves" do
    {:ok, user} = Accounts.register_user(%{email: "self@example.com", username: "selfuser", password: "password123"})
    assert {:error, :cannot_friend_self} = Accounts.send_friend_request(user.id, user.id)
  end

  test "repeating a pending friend request is idempotent" do
    {:ok, sender} = Accounts.register_user(%{email: "sender@example.com", username: "sender", password: "password123"})
    {:ok, recipient} = Accounts.register_user(%{email: "recipient@example.com", username: "recipient", password: "password123"})

    assert {:ok, first} = Accounts.send_friend_request(sender.id, recipient.id)
    assert {:ok, repeated} = Accounts.send_friend_request(sender.id, recipient.id)
    assert repeated.id == first.id
  end

  test "a reverse friend request accepts the existing pending request" do
    {:ok, sender} = Accounts.register_user(%{email: "reverse-sender@example.com", username: "reverse_sender", password: "password123"})
    {:ok, recipient} = Accounts.register_user(%{email: "reverse-recipient@example.com", username: "reverse_recipient", password: "password123"})

    assert {:ok, pending} = Accounts.send_friend_request(sender.id, recipient.id)
    assert {:ok, accepted} = Accounts.send_friend_request(recipient.id, sender.id)
    assert accepted.id == pending.id
    assert accepted.status == :accepted
    assert Enum.map(Accounts.list_friends(sender.id), & &1.id) == [recipient.id]
    assert Enum.map(Accounts.list_friends(recipient.id), & &1.id) == [sender.id]
  end

  test "both users see each other after the recipient accepts" do
    {:ok, sender} = Accounts.register_user(%{email: "accepted-sender@example.com", username: "accepted_sender", password: "password123"})
    {:ok, recipient} = Accounts.register_user(%{email: "accepted-recipient@example.com", username: "accepted_recipient", password: "password123"})

    assert {:ok, request} = Accounts.send_friend_request(sender.id, recipient.id)
    assert {:ok, accepted} = Accounts.respond_to_request(recipient.id, request.id, :accepted)
    assert accepted.status == :accepted
    assert Enum.map(Accounts.list_friends(sender.id), & &1.id) == [recipient.id]
    assert Enum.map(Accounts.list_friends(recipient.id), & &1.id) == [sender.id]
  end
end
