defmodule PingPong.Repo.Migrations.CreateScoresWinnersView do
  use Ecto.Migration

  def change do
    execute "create view scores_winners as
      select
        *,
        CASE
          WHEN winner = 'left' THEN left_id
          WHEN winner = 'right' THEN right_id
          ELSE null
        END as won_by_id,
        CASE
          WHEN winner = 'left' THEN right_id
          WHEN winner = 'right' THEN left_id
          ELSE null
        END as lost_by_id
      from
        scores
      ;", ""
  end
end
