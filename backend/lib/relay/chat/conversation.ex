defmodule Relay.Chat.Conversation do
  use Relay.Schema
  schema "conversations" do
    field :kind, Ecto.Enum, values: [:direct, :group]
    field :name, :string
    field :direct_key, :string
    field :last_message_at, :utc_datetime_usec
    belongs_to :created_by, Relay.Accounts.User
    has_many :memberships, Relay.Chat.Membership
    has_many :messages, Relay.Chat.Message
    timestamps()
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:kind, :name, :direct_key, :created_by_id, :last_message_at]) |> validate_required([:kind, :created_by_id]) |> validate_length(:name, max: 100) |> unique_constraint(:direct_key)
end
