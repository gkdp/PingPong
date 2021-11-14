defmodule PingPong.Seasons.SeasonUser do
  use Ecto.Schema

  alias PingPong.Scoreboard.User
  alias PingPong.Seasons.Season
  alias PingPong.Scores.ScoreView
  alias PingPong.Scores.Elo

  schema "season_user" do
    field :elo, :integer, default: 1000

    belongs_to :season, Season
    belongs_to :user, User

    has_many :elo_history, Elo
    has_many :winnings, ScoreView, foreign_key: :won_by_id
    has_many :losses, ScoreView, foreign_key: :lost_by_id

    timestamps()
  end
end
