defmodule Relay.Repo.Migrations.CreateRelayTables do
  use Ecto.Migration
  def change do
    execute "CREATE EXTENSION IF NOT EXISTS pgcrypto", ""
    execute "CREATE EXTENSION IF NOT EXISTS citext", ""
    create table(:users, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :email, :citext, null: false; add :username, :citext, null: false
      add :display_name, :string; add :avatar_url, :string; add :password_hash, :string, null: false
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:users, [:email]); create unique_index(:users, [:username])
    create table(:friend_requests, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :sender_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :recipient_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :status, :string, null: false, default: "pending"; timestamps(type: :utc_datetime_usec)
    end
    create constraint(:friend_requests, :different_users, check: "sender_id <> recipient_id")
    create unique_index(:friend_requests, [:sender_id, :recipient_id], where: "status = 'pending'", name: :friend_requests_open_unique)
    create table(:conversations, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :kind, :string, null: false; add :name, :string; add :direct_key, :string
      add :last_message_at, :utc_datetime_usec
      add :created_by_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:conversations, [:direct_key], where: "direct_key IS NOT NULL")
    create table(:conversation_memberships, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      add :role, :string, null: false, default: "member"; add :banned_at, :utc_datetime_usec
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:conversation_memberships, [:conversation_id, :user_id])
    create table(:messages, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :body, :text; add :attachment_path, :string; add :attachment_name, :string
      add :attachment_type, :string; add :attachment_size, :bigint; add :deleted_at, :utc_datetime_usec
      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all), null: false
      add :sender_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
    create index(:messages, [:conversation_id, :inserted_at])
    create table(:notifications, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :type, :string, null: false; add :data, :map, null: false, default: %{}; add :read_at, :utc_datetime_usec
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime_usec, updated_at: false)
    end
    create index(:notifications, [:user_id, :inserted_at])
    create table(:calls, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :status, :string, null: false, default: "ringing"; add :started_at, :utc_datetime_usec; add :ended_at, :utc_datetime_usec
      add :conversation_id, references(:conversations, type: :uuid, on_delete: :delete_all), null: false
      add :initiator_id, references(:users, type: :uuid, on_delete: :restrict), null: false
      timestamps(type: :utc_datetime_usec)
    end
    create table(:call_participants, primary_key: false) do
      add :id, :uuid, primary_key: true, default: fragment("gen_random_uuid()")
      add :joined_at, :utc_datetime_usec; add :left_at, :utc_datetime_usec
      add :call_id, references(:calls, type: :uuid, on_delete: :delete_all), null: false
      add :user_id, references(:users, type: :uuid, on_delete: :delete_all), null: false
      timestamps(type: :utc_datetime_usec)
    end
    create unique_index(:call_participants, [:call_id, :user_id])
  end
end
