defmodule PingPong.Seasons.SeasonUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User
  alias PingPong.Seasons.Season
  alias PingPong.Scores.Score
  alias PingPong.Scores.ScoreUser
  alias PingPong.Scores.Elo

  schema "season_user" do
    field :elo, :integer, default: 1000

    belongs_to :season, Season
    belongs_to :user, User

    has_many :elo_history, Elo
    has_many :score_users, ScoreUser
    has_many :scores, through: [:score_users, :score]

    field :count_won, :integer, virtual: true
    field :count_lost, :integer, virtual: true

    timestamps()
  end

  # def get_scores(%__MODULE__{scores: scores}, limit \\ nil) do
  def get_scores(%__MODULE__{scores: scores}, limit \\ nil) do
    scores
    |> Enum.sort_by(&(&1.inserted_at), {:desc, Date})
    |> then(fn scores ->
      if limit do
        scores
        |> Enum.take(limit)
      else
        scores
      end
    end)
  end

  def get_scores_won(%__MODULE__{score_users: score_users}) do
    for %ScoreUser{side: side, score: %Score{winner: winner} = score} when side == winner <- score_users do
      score
    end
  end

  def get_scores_lost(%__MODULE__{score_users: score_users}) do
    for %ScoreUser{side: side, score: %Score{winner: winner} = score} when side != winner <- score_users do
      score
    end
  end

  def get_last_score(%__MODULE__{} = season_user) do
    season_user
    |> get_scores()
    |> List.first()
  end

  @fields ~w(elo season_id user_id)a
  @doc false
  def changeset(season_user, attrs) do
    season_user
    |> cast(attrs, @fields)
    |> validate_required(@fields)
    |> assoc_constraint(:season)
    |> assoc_constraint(:user)
  end
end
