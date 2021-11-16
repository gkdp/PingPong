defmodule PingPong.Scores.ScoreUser do
  use Ecto.Schema

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.Score

  schema "score_user" do
    field :side, Ecto.Enum, values: [:left, :right]

    belongs_to :score, Score
    belongs_to :season_user, SeasonUser

    timestamps()
  end
end
