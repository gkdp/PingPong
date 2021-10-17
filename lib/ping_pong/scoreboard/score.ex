defmodule PingPong.Scoreboard.Score do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User

  schema "scores" do
    field :left_score, :integer
    field :right_score, :integer

    belongs_to :left, User
    belongs_to :right, User
    belongs_to :winner, User

    field :confirmed_at, :naive_datetime

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:left_id, :right_id, :winner_id, :left_score, :right_score])
    |> validate_required([:left_id, :right_id, :winner_id, :left_score, :right_score])
    |> assoc_constraint(:left)
    |> assoc_constraint(:right)
    |> assoc_constraint(:winner)
  end
end
