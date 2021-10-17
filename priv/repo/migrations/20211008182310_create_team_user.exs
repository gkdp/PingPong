defmodule PingPong.Repo.Migrations.CreateTeamUser do
  use Ecto.Migration

  def change do
    create table(:team_user) do
      add :team_id, references(:teams), null: false
      add :user_id, references(:users), null: false

      timestamps()
    end
  end
end
