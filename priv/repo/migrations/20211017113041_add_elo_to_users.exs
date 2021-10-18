defmodule PingPong.Repo.Migrations.AddEloToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :elo, :integer, default: 1000, null: false
    end
  end
end
