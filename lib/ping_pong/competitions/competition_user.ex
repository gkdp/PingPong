defmodule PingPong.Competitions.CompetitionUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User
  alias PingPong.Competitions.Competition

  schema "competition_user" do
    field :elo, :integer, default: 1000

    belongs_to :competition, Competition
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(competition, attrs) do
    competition
    |> cast(attrs, [:title, :start_at, :end_at])
    |> validate_required([:start_at, :end_at])
  end
end
