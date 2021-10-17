defmodule PingPongWeb.CommandController do
  use PingPongWeb, :controller

  alias PingPong.Commands
  alias PingPong.Scoreboard

  action_fallback PingPongWeb.FallbackController

  def command(conn, %{"command" => "/match", "text" => "report" <> text} = params) do
    with %Commands.Report{} = command <- report(text, params),
         {:ok, score} <- Scoreboard.process_score(command) do
      conn
      |> render("report.json", score: PingPong.Repo.preload(score, [:winner, :left, :right]))
    else
      _ ->
        conn
        |> resp(200, "")
    end
  end

  def command(conn, _) do
    IO.inspect("Fail")

    conn
    |> resp(200, "")
  end

  defp report(text, params) do
    processed =
      Regex.named_captures(
        ~r/<@(?<id>.+)\|(?<name>.+)>(\s+?)(?<own>\d+):(?<other>\d+)/,
        String.trim(String.replace(text, <<160::utf8>>, " "))
      )

    with %{} <- processed, user_id <- params["user_id"] do
      %Commands.Report{
        left_id: user_id,
        right_id: Map.get(processed, "id"),
        left: String.to_integer(Map.get(processed, "own")),
        right: String.to_integer(Map.get(processed, "other"))
      }
    end
  end

  # def command(conn, %{"command" => "/match", "text" => text} = params) do
  #   aa =
  #     Chat.post_ephemeral(
  #       params["channel_id"],
  #       "#{text} heeft je uitgedaagd. Accepteer je?",
  #       "U049H2SAV",
  #       %{
  #         blocks:
  #           Jason.encode!([
  #             %{
  #               type: "section",
  #               text: %{
  #                 type: "plain_text",
  #                 text: "#{text} heeft je uitgedaagd. Accepteer je?",
  #                 emoji: true
  #               }
  #             },
  #             %{
  #                 type: "actions",
  #                 elements: [
  #                   %{
  #                     type: "button",
  #                     text: %{
  #                       type: "plain_text",
  #                       emoji: true,
  #                       text: "Accepteer"
  #                     },
  #                     style: "primary",
  #                     value: "click_me_123"
  #                   },
  #                   %{
  #                     type: "button",
  #                     text: %{
  #                       type: "plain_text",
  #                       emoji: true,
  #                       text: "Weiger"
  #                     },
  #                     style: "danger",
  #                     value: "click_me_123"
  #                   }
  #                 ]
  #               }
  #           ])
  #       }
  #     )

  #   IO.inspect(aa)

  #   conn
  #   |> render("match.json", command: %Command{})
  # end

  # def index(conn, _params) do
  #   commands = Slack.list_commands()
  #   render(conn, "index.json", commands: commands)
  # end

  # def create(conn, %{"command" => command_params}) do
  #   with {:ok, %Command{} = command} <- Slack.create_command(command_params) do
  #     conn
  #     |> put_status(:created)
  #     |> put_resp_header("location", Routes.command_path(conn, :show, command))
  #     |> render("show.json", command: command)
  #   end
  # end

  # def show(conn, %{"id" => id}) do
  #   command = Slack.get_command!(id)
  #   render(conn, "show.json", command: command)
  # end

  # def update(conn, %{"id" => id, "command" => command_params}) do
  #   command = Slack.get_command!(id)

  #   with {:ok, %Command{} = command} <- Slack.update_command(command, command_params) do
  #     render(conn, "show.json", command: command)
  #   end
  # end

  # def delete(conn, %{"id" => id}) do
  #   command = Slack.get_command!(id)

  #   with {:ok, %Command{}} <- Slack.delete_command(command) do
  #     send_resp(conn, :no_content, "")
  #   end
  # end
end
