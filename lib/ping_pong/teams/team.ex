defmodule PingPong.Teams.Team do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.User

  schema "teams" do
    field :name, :string

    many_to_many :users, User, join_through: "team_user"

    timestamps()
  end

  @doc false
  def changeset(team, attrs) do
    team
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
