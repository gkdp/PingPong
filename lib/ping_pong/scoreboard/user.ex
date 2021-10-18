defmodule PingPong.Scoreboard.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.ScoreWinner

  schema "users" do
    field :slack_id, :string
    field :name, :string
    field :email, :string
    field :elo, :integer, default: 1000

    has_many :winnings, ScoreWinner, foreign_key: :won_by_id

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
          _ -> {:ignore, nil}
        end
      end)

      case user do
        %{"profile" => %{"real_name" => name}} -> name
        _ -> "Naam niet bekend"
      end
  end
end
