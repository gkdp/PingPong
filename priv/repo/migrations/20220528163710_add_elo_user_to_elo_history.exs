defmodule PingPong.Repo.Migrations.AddEloUserToEloHistory do
  use Ecto.Migration

  def change do
    alter table(:elo_history) do
      add :elo_user, :integer, default: 1000, null: false
    end
  end
end
