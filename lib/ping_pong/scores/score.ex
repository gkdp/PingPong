defmodule PingPong.Scores.Score do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Seasons.SeasonUser

  schema "scores" do
    field :winner, Ecto.Enum, values: [:left, :right, :draw]
    field :left_score, :integer
    field :right_score, :integer
    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    belongs_to :left, SeasonUser
    belongs_to :right, SeasonUser

    timestamps()
  end

  @fields ~w(winner left_score right_score left_id right_id)a
  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:left)
    |> assoc_constraint(:right)
  end
end
