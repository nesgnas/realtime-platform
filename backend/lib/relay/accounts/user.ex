defmodule Relay.Accounts.User do
  use Relay.Schema
  schema "users" do
    field :email, :string
    field :username, :string
    field :display_name, :string
    field :avatar_url, :string
    field :password, :string, virtual: true, redact: true
    field :password_hash, :string, redact: true
    has_many :notifications, Relay.Notifications.Notification
    timestamps()
  end
  def changeset(user, attrs) do
    user |> cast(attrs, [:email, :username, :display_name, :avatar_url, :password]) |> update_change(:email, &String.downcase/1) |> update_change(:username, &String.downcase/1) |> validate_required([:email, :username, :password]) |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/) |> validate_length(:username, min: 3, max: 32) |> validate_length(:password, min: 8, max: 72) |> unique_constraint(:email) |> unique_constraint(:username) |> hash_password()
  end
  def profile_changeset(user, attrs), do: user |> cast(attrs, [:display_name, :avatar_url]) |> validate_length(:display_name, max: 80)
  defp hash_password(%Ecto.Changeset{valid?: true, changes: %{password: password}} = cs), do: put_change(cs, :password_hash, Bcrypt.hash_pwd_salt(password))
  defp hash_password(cs), do: cs
end
