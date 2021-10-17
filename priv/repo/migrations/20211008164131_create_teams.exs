defmodule PingPong.Repo.Migrations.CreateTeams do
  use Ecto.Migration

  def change do
    create table(:teams) do
      add :slack_channel_id, :string
      add :slack_bot_id, :string
      add :name, :string

      timestamps()
    end
  end
end
