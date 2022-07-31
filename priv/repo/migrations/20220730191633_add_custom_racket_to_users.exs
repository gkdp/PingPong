defmodule PingPong.Repo.Migrations.AddCustomRacketToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :custom_racket, :boolean, default: false, null: false
    end
  end
end
