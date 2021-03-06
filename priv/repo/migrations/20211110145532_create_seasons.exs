defmodule PingPong.Repo.Migrations.CreateSeasons do
  use Ecto.Migration

  def change do
    create table(:seasons) do
      add :title, :string
      add :description, :text
      add :start_at, :naive_datetime
      add :end_at, :naive_datetime

      # add :team_id, references(:teams), null: true

      timestamps()
    end
  end
end
