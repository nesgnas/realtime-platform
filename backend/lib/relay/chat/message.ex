defmodule Relay.Chat.Message do
  use Relay.Schema
  schema "messages" do
    field :body, :string
    field :attachment_path, :string
    field :attachment_name, :string
    field :attachment_type, :string
    field :attachment_size, :integer
    field :deleted_at, :utc_datetime_usec
    belongs_to :conversation, Relay.Chat.Conversation
    belongs_to :sender, Relay.Accounts.User
    timestamps(updated_at: false)
  end
  def changeset(row, attrs) do
    row |> cast(attrs, [:body, :attachment_path, :attachment_name, :attachment_type, :attachment_size, :conversation_id, :sender_id]) |> validate_required([:conversation_id, :sender_id]) |> validate_length(:body, max: 10_000) |> validate_content()
  end
  defp validate_content(cs), do: if(get_field(cs, :body) in [nil, ""] and is_nil(get_field(cs, :attachment_path)), do: add_error(cs, :body, "or attachment is required"), else: cs)
end
