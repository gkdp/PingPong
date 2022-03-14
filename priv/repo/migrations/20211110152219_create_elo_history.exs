defmodule PingPong.Repo.Migrations.CreateScoreHistory do
  use Ecto.Migration

  def change do
    create table(:elo_history) do
      add :score_id, references(:scores), null: false
      add :season_user_id, references(:seasons), null: false

      add :elo, :integer, default: 1000, null: false

      timestamps()
    end
  end
end
