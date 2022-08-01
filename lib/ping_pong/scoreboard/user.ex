defmodule PingPong.Scoreboard.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Seasons.SeasonUser
  alias PingPong.Teams.Team

  schema "users" do
    field :slack_id, :string
    field :name, :string
    field :custom_racket, :boolean
    field :elo, :integer, default: 1000

    has_one :season_user, SeasonUser
    has_many :season_users, SeasonUser
    many_to_many :teams, Team, join_through: "team_user"
    has_many :elo_history, through: [:season_users, :elo_history]

    embeds_one :settings, Settings, on_replace: :delete, primary_key: false do
      field :show_pictures, :boolean, default: false
      field :hide_teams, :boolean, default: false
    end

    field :count_won, :integer, virtual: true
    field :count_lost, :integer, virtual: true

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slack_id, :name, :elo, :custom_racket])
    |> cast_embed(:settings, with: &settings_changeset/2)
  end

  defp settings_changeset(schema, params) do
    schema
    |> cast(params, [:show_pictures, :hide_teams])
  end

  defp get_slack(%__MODULE__{slack_id: id}) do
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

    user
  end

  def get_slack_name(%__MODULE__{slack_id: _id} = slack) do
    case get_slack(slack) do
      %{"profile" => %{"real_name" => name}} -> name
      _ -> "Naam niet bekend"
    end
  end

  def get_slack_avatar(%__MODULE__{slack_id: _id} = slack) do
    case get_slack(slack) do
      %{"profile" => %{"image_48" => image}} -> image
      _ -> nil
    end
  end

  def get_slack_name_short(%__MODULE__{} = user) do
    List.first(String.split(get_slack_name(user)), "Anoniem")
  end
end
