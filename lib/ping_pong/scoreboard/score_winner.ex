defmodule PingPong.Scoreboard.ScoreWinner do
  use Ecto.Schema

  alias PingPong.Scoreboard.User

  schema "scores_winners" do
    field :left_score, :integer
    field :right_score, :integer
    field :winner, Ecto.Enum, values: [:left, :right, :draw]

    belongs_to :left, User
    belongs_to :right, User
    belongs_to :won_by, User

    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    timestamps()
  end
end
