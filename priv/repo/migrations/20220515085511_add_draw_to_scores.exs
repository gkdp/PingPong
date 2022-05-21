defmodule PingPong.Repo.Migrations.AddDrawToScores do
  use Ecto.Migration

  def change do
    alter table(:scores) do
      add :draw, :boolean, default: false, null: false
    end
  end
end
