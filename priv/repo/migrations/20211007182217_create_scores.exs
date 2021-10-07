defmodule PingPong.Repo.Migrations.CreateScores do
  use Ecto.Migration

  def change do
    create table(:scores) do
      add :left, :integer
      add :right, :integer

      timestamps()
    end
  end
end
