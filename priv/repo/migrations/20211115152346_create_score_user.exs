defmodule PingPong.Repo.Migrations.CreateScoreUser do
  use Ecto.Migration

  def change do
    create table(:score_user) do
      add :side, :string, null: false
      add :score_id, references(:scores), null: false
      add :season_user_id, references(:season_user), null: false

      timestamps()
    end
  end
end
