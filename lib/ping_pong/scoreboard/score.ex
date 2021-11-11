defmodule PingPong.Scoreboard.Score do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User
  alias PingPong.Competitions.Competition

  schema "scores" do
    field :left_score, :integer
    field :right_score, :integer
    field :winner, Ecto.Enum, values: [:left, :right, :draw]

    belongs_to :competition, Competition
    belongs_to :left, User
    belongs_to :right, User

    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:left_id, :right_id, :winner, :left_score, :right_score])
    |> validate_required([:left_id, :right_id, :winner, :left_score, :right_score])
    |> assoc_constraint(:left)
    |> assoc_constraint(:right)
  end
end
