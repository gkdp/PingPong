defmodule PingPong.Teams.TeamUser do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Teams.Team
  alias PingPong.Scoreboard.User

  schema "team_user" do
    belongs_to :team, Team
    belongs_to :user, User

    timestamps()
  end

  @doc false
  def changeset(team_user, attrs) do
    team_user
    |> cast(attrs, [:user_id, :team_id])
    |> validate_required([:user_id, :team_id])
  end
end
