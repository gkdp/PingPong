defmodule PingPong.Scores.Elo do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scores.Score
  alias PingPong.Seasons.SeasonUser

  schema "elo_history" do
    field :elo, :integer, default: 1000

    belongs_to :season_user, SeasonUser
    belongs_to :score, Score

    timestamps()
  end

  @fields ~w(elo season_user_id score_id)a
  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:season_user)
    |> assoc_constraint(:score)
  end
end
