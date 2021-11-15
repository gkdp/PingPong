defmodule PingPongWeb.CommandController do
  use PingPongWeb, :controller

  alias PingPong.Commands.Report
  alias PingPong.Commands.DoublesReport
  alias PingPong.Scoreboard
  alias PingPong.Seasons.Season
  alias PingPong.Seasons

  action_fallback PingPongWeb.FallbackController

  def command(conn, %{"command" => "/match", "text" => "report" <> text} = params) do
    with %Report{} = report <- report(text, params) do
      with {:ok, scores} <- Scoreboard.process_scores(report) do
        conn
        |> render("report.json",
          scores: PingPong.Repo.preload(scores, left: [:user], right: [:user])
        )
      else
        {:error, :equals} ->
          conn
          |> render("equals.json")

        {:error, :season_not_found} ->
          conn
          |> render("season_not_found.json")

        _ ->
          conn
          |> render("error.json")
      end
    end
  end

  # def command(conn, %{"command" => "/match", "text" => "doubles" <> text} = params) do
  #   with %Report{} = report <- report_doubles(text, params) do
  #     with {:ok, scores} <- Scoreboard.process_scores(report) do
  #       # conn
  #       # |> render("report_doubles.json",
  #       #   scores: PingPong.Repo.preload(scores, left: [:user], right: [:user])
  #       # )
  #     else
  #       {:error, :equals} ->
  #         conn
  #         |> render("equals.json")

  #       {:error, :season_not_found} ->
  #         conn
  #         |> render("season_not_found.json")

  #       _ ->
  #         conn
  #         |> render("error.json")
  #     end
  #   end
  # end

  def command(conn, %{"command" => "/match", "text" => "score" <> text} = params) do
    processed =
      Regex.named_captures(
        ~r/<@(?<id>.+)\|(?<name>.+)>/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    season = Seasons.get_active_season()

    with %Season{} <- season, id when id != :no_id <- Map.get(processed || %{}, "id", :no_id) do
      case Scoreboard.get_or_create_user_by_slack(id) do
        {:ok, user} ->
          user = Scoreboard.get_or_create_season_user_for_user(user, season.id)

          conn
          |> render("player_score.json", slack_id: user.slack_id, elo: user.season_user.elo)

        {:error, _} ->
          conn
          |> render("error.json")
      end
    else
      nil ->
        conn
        |> render("season_not_found.json")

      _ ->
        case Scoreboard.get_or_create_user_by_slack(params["user_id"]) do
          {:ok, user} ->
            user = Scoreboard.get_or_create_season_user_for_user(user, season.id)

            conn
            |> render("personal_score.json", elo: user.season_user.elo)

          {:error, _} ->
            conn
            |> render("error.json")
        end
    end
  end

  def command(conn, _) do
    conn
    |> render("help.json")
  end

  defp report(text, params) do
    processed =
      Regex.named_captures(
        ~r/<@(?<id>.+)\|(?<name>.+)>(\s+?)(?<scores>.*)/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    with %{"id" => right_id, "scores" => scores} <- processed, left_id <- params["user_id"] do
      scores =
        for score <- String.split(scores, ~r/\s+/) do
          with %{"left" => left, "right" => right} <-
                 Regex.named_captures(~r/(?<left>\d+):(?<right>\d+)/, score) do
            %Report.Score{
              left: String.to_integer(left),
              right: String.to_integer(right)
            }
          end
        end

      %Report{
        left_id: left_id,
        right_id: right_id,
        scores: Enum.filter(scores, &(!is_nil(&1)))
      }
    end
  end

  # defp report_doubles(text, params) do
  #   processed =
  #     Regex.named_captures(
  #       ~r/<@(?<buddy_id>.+)\|(.+)>(\s+?)report(\s+?)<@(?<opponent_id>.+)\|(.+)>(\s+?)<@(?<opponnent_id_buddy>.+)\|(.+)>(\s+?)(?<scores>.*)/,
  #       String.trim(String.replace(text, <<160::utf8>>, " "))
  #     )

  #   with %{"scores" => scores} <- processed, id <- params["user_id"] do
  #     scores =
  #       for score <- String.split(scores, ~r/\s+/) do
  #         with %{"left" => left, "right" => right} <-
  #                Regex.named_captures(~r/(?<left>\d+):(?<right>\d+)/, score) do
  #           %Report.Score{
  #             left: String.to_integer(left),
  #             right: String.to_integer(right)
  #           }
  #         end
  #       end

  #     %DoublesReport{
  #       left_id: id,
  #       left_id_buddy: Map.get(processed, "buddy_id"),
  #       right_id: Map.get(processed, "opponent_id"),
  #       right_id_buddy: Map.get(processed, "opponent_id_buddy"),
  #       scores: Enum.filter(scores, &(!is_nil(&1)))
  #     }
  #   end
  # end
end
