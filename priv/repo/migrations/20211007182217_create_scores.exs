defmodule PingPong.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :left_score, :integer, null: false
      add :right_score, :integer, null: false

      add :winner, :string
      add :left_id, references(:season_users), null: false
      add :right_id, references(:season_users), null: false

      add :confirmed_at, :naive_datetime
      add :denied_at, :naive_datetime

      timestamps()
    end
  end
end
