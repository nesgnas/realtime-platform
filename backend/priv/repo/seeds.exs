alias Relay.Accounts
for attrs <- [
  %{email: "alice@example.com", username: "alice", display_name: "Alice", password: "password123"},
  %{email: "bob@example.com", username: "bob", display_name: "Bob", password: "password123"}
] do
  case Accounts.register_user(attrs) do
    {:ok, _} -> :ok
    {:error, %Ecto.Changeset{errors: errors}} -> IO.inspect(errors, label: "seed skipped")
  end
end
