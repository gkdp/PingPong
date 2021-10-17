defmodule PingPong.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :left_score, :integer, null: false
      add :right_score, :integer, null: false

      add :left_id, references(:users), null: false
      add :right_id, references(:users), null: false
      add :winner_id, references(:users)

      add :confirmed_at, :naive_datetime

      timestamps()
    end
  end
end
