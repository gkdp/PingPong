defmodule PingPong.Scoreboard.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Teams.Team

  schema "users" do
    field :slack_id, :string
    field :name, :string

    has_one :season_user, SeasonUser
    has_many :season_users, SeasonUser
    many_to_many :teams, Team, join_through: "team_user"

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slack_id, :name, :email, :elo])
  end

  def get_slack_name(%__MODULE__{slack_id: id}) do
    {_, user} =
      Cachex.fetch(:slack_profiles, id, fn _ ->
        with %{"ok" => true, "user" => user} <- Slack.Web.Users.info(id) do
          {:commit, user}
        else
          e ->
            IO.inspect("Failed getting Slack info")
            IO.inspect(e)

            {:commit, :not_found}
        end
      end)

    case user do
      %{"profile" => %{"real_name" => name}} -> name
      _ -> "Naam niet bekend"
    end
  end

  def get_slack_name_short(%__MODULE__{} = user) do
    List.first(String.split(get_slack_name(user)), "Anoniem")
  end
end
