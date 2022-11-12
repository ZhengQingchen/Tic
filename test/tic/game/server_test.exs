defmodule Tic.Game.ServerTest do
  use ExUnit.Case, async: true

  alias Tic.Game.Server

  @default_board [0, 1, 2, 3, 4, 5, 6, 7, 8]

  describe "check_status/1" do
    test "default status is pending" do
      assert :pending = Server.check_status(@default_board)
    end

    test "pending" do
      assert :pending = Server.check_status(["o", "x", 2, 3, 4, 5, 6, 7, 8])
    end

    test "win" do
      assert {:win, "x", [0, 1, 2]} = Server.check_status(["x", "x", "x", 3, 4, 5, 6, 7, 8])
      assert {:win, "o", [0, 1, 2]} = Server.check_status(["o", "o", "o", 3, 4, 5, 6, 7, 8])
    end

    test "draw" do
      assert :draw = Server.check_status(["o", "o", "x", "x", "x", "o", "o", "o", "x"])
    end
  end
end
