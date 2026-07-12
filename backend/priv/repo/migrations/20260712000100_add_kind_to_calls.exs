defmodule Relay.Repo.Migrations.AddKindToCalls do
  use Ecto.Migration

  def change do
    alter table(:calls) do
      add :kind, :string, null: false, default: "voice"
    end
  end
end
