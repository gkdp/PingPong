defmodule PingPong.Repo.Migrations.CreateSeasonUser do
  use Ecto.Migration

  def change do
    create table(:season_user) do
      add :season_id, references(:seasons), null: false
      add :user_id, references(:users), null: false

      add :elo, :integer, default: 1000, null: false

      timestamps()
    end
  end
end
