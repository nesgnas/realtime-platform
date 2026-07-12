defmodule Relay.Chat.Membership do
  use Relay.Schema
  schema "conversation_memberships" do
    field :role, Ecto.Enum, values: [:member, :admin, :owner], default: :member
    field :banned_at, :utc_datetime_usec
    belongs_to :conversation, Relay.Chat.Conversation
    belongs_to :user, Relay.Accounts.User
    timestamps()
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:conversation_id, :user_id, :role, :banned_at]) |> validate_required([:conversation_id, :user_id, :role]) |> unique_constraint([:conversation_id, :user_id])
end
