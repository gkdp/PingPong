defmodule PingPong.Scoreboard.User do
  use Ecto.Schema
  import Ecto.Changeset

  alias PingPong.Scoreboard.ScoreWinner
  alias PingPong.Scoreboard.EloHistory

  schema "users" do
    field :slack_id, :string
    field :name, :string
    field :email, :string
    field :elo, :integer, default: 1000

    has_many :winnings, ScoreWinner, foreign_key: :won_by_id
    has_many :losses, ScoreWinner, foreign_key: :lost_by_id
    has_many :elo_history, EloHistory

    field :winnings_count, :integer, virtual: true
    field :losses_count, :integer, virtual: true

    timestamps()
  end

  def changeset(user, attrs) do
    user
    |> cast(attrs, [:slack_id, :name, :email, :elo])
  end

  # def get_slack_info(%__MODULE__{slack_id: id}) do
  #   {_, user} =
  #     Cachex.fetch(:slack_profiles, id, fn _ ->
  #       with %{"ok" => true, "user" => user} <- Slack.Web.Users.info(id) do
  #         {:commit, user}
  #       else
  #         e ->
  #           IO.inspect("Failed getting Slack info")
  #           IO.inspect(e)

  #           {:ignore, nil}
  #       end
  #     end)

  #     case user do
  #       %{"profile" => %{"real_name" => name}} -> name
  #       _ -> "Naam niet bekend"
  #     end
  # end

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
