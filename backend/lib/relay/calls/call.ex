defmodule Relay.Calls.Call do
  use Relay.Schema
  schema "calls" do
    field :status, Ecto.Enum, values: [:ringing, :active, :ended, :missed], default: :ringing
    field :kind, Ecto.Enum, values: [:voice, :video], default: :voice
    field :started_at, :utc_datetime_usec
    field :ended_at, :utc_datetime_usec
    belongs_to :conversation, Relay.Chat.Conversation
    belongs_to :initiator, Relay.Accounts.User
    has_many :participants, Relay.Calls.Participant
    timestamps()
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:status, :kind, :started_at, :ended_at, :conversation_id, :initiator_id]) |> validate_required([:status, :kind, :conversation_id, :initiator_id])
end
