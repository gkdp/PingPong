defmodule PingPong.Repo.Migrations.CreateScoreHistory do
  use Ecto.Migration

  def change do
    create table(:elo_history) do
      add :user_id, references(:users), null: false
      add :score_id, references(:scores), null: false
      add :competition_id, references(:competitions), null: true

      add :elo, :integer, default: 1000, null: false

      timestamps()
    end
  end
end
