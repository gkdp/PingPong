defmodule PingPong.SlackTest do
  use PingPong.DataCase

  alias PingPong.Slack

  describe "commands" do
    alias PingPong.Slack.Command

    import PingPong.SlackFixtures

    @invalid_attrs %{response_type: nil}

    test "list_commands/0 returns all commands" do
      command = command_fixture()
      assert Slack.list_commands() == [command]
    end

    test "get_command!/1 returns the command with given id" do
      command = command_fixture()
      assert Slack.get_command!(command.id) == command
    end

    test "create_command/1 with valid data creates a command" do
      valid_attrs = %{response_type: "some response_type"}

      assert {:ok, %Command{} = command} = Slack.create_command(valid_attrs)
      assert command.response_type == "some response_type"
    end

    test "create_command/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Slack.create_command(@invalid_attrs)
    end

    test "update_command/2 with valid data updates the command" do
      command = command_fixture()
      update_attrs = %{response_type: "some updated response_type"}

      assert {:ok, %Command{} = command} = Slack.update_command(command, update_attrs)
      assert command.response_type == "some updated response_type"
    end

    test "update_command/2 with invalid data returns error changeset" do
      command = command_fixture()
      assert {:error, %Ecto.Changeset{}} = Slack.update_command(command, @invalid_attrs)
      assert command == Slack.get_command!(command.id)
    end

    test "delete_command/1 deletes the command" do
      command = command_fixture()
      assert {:ok, %Command{}} = Slack.delete_command(command)
      assert_raise Ecto.NoResultsError, fn -> Slack.get_command!(command.id) end
    end

    test "change_command/1 returns a command changeset" do
      command = command_fixture()
      assert %Ecto.Changeset{} = Slack.change_command(command)
    end
  end
end
