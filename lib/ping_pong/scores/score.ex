defmodule PingPong.Scores.Score do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Scores.ScoreUser
  alias PingPong.Scores.Elo

  schema "scores" do
    field :winner, Ecto.Enum, values: [:left, :right, :draw]
    field :draw, :boolean, default: false
    field :left_score, :integer
    field :right_score, :integer
    field :confirmed_at, :naive_datetime
    field :denied_at, :naive_datetime

    has_many :score_users, ScoreUser
    has_many :elo_history, Elo
    has_many :season_users, through: [:score_users, :season_user]
    has_many :users, through: [:score_users, :season_user, :user]

    timestamps()
  end

  def get_side(%__MODULE__{score_users: score_users}, %SeasonUser{id: id}) do
    score_users
    |> Enum.find(&(&1.season_user_id == id))
    |> Map.get(:side, :unknown)
  end

  def get_score_users(%__MODULE__{score_users: score_users}, side) do
    score_users
    |> Enum.filter(&(&1.side == side))
  end

  def get_winning_score_users(%__MODULE__{winner: winner} = score) do
    score
    |> get_score_users(winner)
  end

  def get_losing_score_users(%__MODULE__{winner: winner} = score) do
    score
    |> get_score_users(if(winner == :left, do: :right, else: :left))
  end

  @fields ~w(winner draw left_score right_score)a
  @doc false
  def changeset(score, attrs) do
    score
    |> cast(attrs, @fields)
    |> validate_required(@fields)
  end
end
