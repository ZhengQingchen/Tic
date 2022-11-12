defmodule Tic.GameTest do
  use ExUnit.Case

  alias Tic.Game

  @registry :game_registry

  describe "start/1" do
    test "can start a new game" do
      game_id = Ecto.UUID.generate()
      assert {:ok, pid} = Game.start(game_id)
      assert [{^pid, nil}] = Registry.lookup(@registry, game_id)
    end

    test "return error when try to start a duplicate game" do
      game_id = Ecto.UUID.generate()
      assert {:ok, pid} = Game.start(game_id)
      assert {:error, {:already_started, ^pid}} = Game.start(game_id)
      assert [{^pid, nil}] = Registry.lookup(@registry, game_id)
    end
  end

  describe "join/1" do
    setup :start_game

    test "can join a game and return a player role successfully", %{game_id: game_id} do
      assert {:ok, "x", %{pending_roles: ["o"]}} = Game.join(game_id)
      assert {:ok, "o", %{pending_roles: []}} = Game.join(game_id)
    end

    test "can not join a game when there is no vacancy", %{game_id: game_id} do
      Game.join(game_id)
      Game.join(game_id)
      assert {:error, :can_not_join} = Game.join(game_id)
    end
  end

  describe "leave/2" do
    setup :start_game

    test "can leave the game after join", %{game_id: game_id} do
      {:ok, role_1, _state} = Game.join(game_id)
      {:ok, _role_2, _state} = Game.join(game_id)
      assert :ok = Game.leave(game_id, role_1)
      assert %{pending_roles: [^role_1]} = Game.Server.state(game_id)
    end

    test "terminate game server when all players leave", %{game_id: game_id} do
      {:ok, role_1, _state} = Game.join(game_id)
      {:ok, role_2, _state} = Game.join(game_id)
      assert :ok = Game.leave(game_id, role_1)
      assert :ok = Game.leave(game_id, role_2)
      Process.sleep(10)
      assert [] = Registry.lookup(@registry, game_id)
    end
  end

  describe "move/3" do
    setup :start_game

    test "can move to index when is your turn", %{game_id: game_id} do
      {:ok, "x", %{active_player: "x"}} = Game.join(game_id)
      assert {:ok, new_state} = Game.move(game_id, "x", 0)

      assert new_state.active_player == "o"
      assert ["x" | _] = new_state.board
      assert new_state.status == :pending
    end

    test "can not move to index when is not your turn", %{game_id: game_id} do
      {:ok, "x", %{active_player: "x"}} = Game.join(game_id)
      assert {:error, :not_your_turn} = Game.move(game_id, "o", 0)
    end

    test "can not move when status is not pending", %{game_id: game_id} do
      {:ok, "x", %{active_player: "x"}} = Game.join(game_id)

      # mock game ended
      :sys.replace_state(
        {:via, Registry, {@registry, game_id}},
        fn state ->
          %{state | status: :win}
        end
      )

      assert {:error, :game_ended} = Game.move(game_id, "x", 0)
    end

    test "can not move to index have alrady moved", %{game_id: game_id} do
      {:ok, "x", %{active_player: "x"}} = Game.join(game_id)
      assert {:ok, _state} = Game.move(game_id, "x", 0)
      assert {:ok, _state} = Game.move(game_id, "o", 1)

      assert {:error, :duplicated_move} = Game.move(game_id, "x", 0)
      assert {:error, :duplicated_move} = Game.move(game_id, "x", 1)
    end
  end

  def start_game(_ctx) do
    game_id = Ecto.UUID.generate()
    Game.start(game_id)
    %{game_id: game_id}
  end
end
