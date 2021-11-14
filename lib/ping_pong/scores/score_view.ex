defmodule PingPong.Scores.ScoreView do
  use Ecto.Schema

  alias PingPong.Seasons.SeasonUser

  schema "scores_extra" do
    field :winner, Ecto.Enum, values: [:left, :right, :draw]
    field :left_score, :integer
    field :right_score, :integer
    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    belongs_to :left, SeasonUser
    belongs_to :right, SeasonUser
    belongs_to :won_by, SeasonUser
    belongs_to :lost_by, SeasonUser

    timestamps()
  end
end
