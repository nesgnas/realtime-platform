defmodule Relay.Accounts.FriendRequest do
  use Relay.Schema
  schema "friend_requests" do
    field :status, Ecto.Enum, values: [:pending, :accepted, :declined, :cancelled], default: :pending
    belongs_to :sender, Relay.Accounts.User
    belongs_to :recipient, Relay.Accounts.User
    timestamps()
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:sender_id, :recipient_id, :status]) |> validate_required([:sender_id, :recipient_id]) |> check_constraint(:recipient_id, name: :different_users) |> unique_constraint([:sender_id, :recipient_id], name: :friend_requests_open_unique)
end
