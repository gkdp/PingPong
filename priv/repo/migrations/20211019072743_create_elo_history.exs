defmodule PingPong.Repo.Migrations.CreateScoreHistory do
  use Ecto.Migration

  def change do
    create table(:elo_history) do
      add :user_id, references(:users), null: false
      add :score_id, references(:scores), null: false
      add :elo, :integer, null: false

      timestamps()
    end
  end
end
