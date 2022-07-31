defmodule PingPong.Repo.Migrations.AddSettingsToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :settings, :map, default: %{}, null: false
    end
  end
end
