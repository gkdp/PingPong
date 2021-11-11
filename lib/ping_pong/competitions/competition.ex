defmodule PingPong.Competitions.Competition do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User
  alias PingPong.Competitions.CompetitionUser

  schema "competitions" do
    field :title, :string
    field :description, :string
    field :start_at, :naive_datetime
    field :end_at, :naive_datetime

    many_to_many :users, User, join_through: CompetitionUser

    timestamps()
  end

  @doc false
  def changeset(competition, attrs) do
    competition
    |> cast(attrs, [:title, :start_at, :end_at])
    |> validate_required([:start_at, :end_at])
  end
end
