defmodule PingPong.Repo.Migrations.AddSeasonIdToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :season_id, references(:seasons), null: true
    end
  end
end
