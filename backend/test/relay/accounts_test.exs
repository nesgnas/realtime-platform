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
end
