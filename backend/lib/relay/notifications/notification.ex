defmodule Relay.Notifications.Notification do
  use Relay.Schema
  schema "notifications" do
    field :type, :string
    field :data, :map, default: %{}
    field :read_at, :utc_datetime_usec
    belongs_to :user, Relay.Accounts.User
    timestamps(updated_at: false)
  end
  def changeset(row, attrs), do: row |> cast(attrs, [:type, :data, :read_at, :user_id]) |> validate_required([:type, :user_id])
end
