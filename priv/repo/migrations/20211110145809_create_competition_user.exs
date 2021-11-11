defmodule PingPong.Repo.Migrations.CreateCompetitionUser do
  use Ecto.Migration

  def change do
    create table(:competition_user) do
      add :competition_id, references(:competitions), null: false
      add :user_id, references(:users), null: false

      add :elo, :integer, default: 1000, null: false

      timestamps()
    end
  end
end
