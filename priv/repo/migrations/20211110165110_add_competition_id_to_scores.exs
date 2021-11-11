defmodule PingPong.Repo.Migrations.AddCompetitionIdToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :competition_id, references(:competitions), null: true
    end
  end
end
