defmodule Relay.Calls.Participant do
  use Relay.Schema
  schema "call_participants" do
    field :joined_at, :utc_datetime_usec
    field :left_at, :utc_datetime_usec
    belongs_to :call, Relay.Calls.Call
    belongs_to :user, Relay.Accounts.User
    timestamps()
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:call_id, :user_id, :joined_at, :left_at]) |> validate_required([:call_id, :user_id]) |> unique_constraint([:call_id, :user_id])
end
