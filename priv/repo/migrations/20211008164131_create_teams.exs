defmodule PingPong.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :name, :string

      add :parent_id, references(:teams), null: true

      timestamps()
    end
  end
end
