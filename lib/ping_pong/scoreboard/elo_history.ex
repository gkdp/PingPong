defmodule PingPong.Scoreboard.EloHistory do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User
  alias PingPong.Scoreboard.Score
  alias PingPong.Competitions.Competition

  schema "elo_history" do
    field :elo, :integer, default: 1000

    belongs_to :user, User
    belongs_to :score, Score
    belongs_to :competition, Competition

    timestamps()
  end

  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, [:elo, :user_id, :score_id, :competition_id])
    |> validate_required([:elo, :user_id, :score_id])
    |> assoc_constraint(:user)
    |> assoc_constraint(:score)
    |> assoc_constraint(:competition)
  end
end
