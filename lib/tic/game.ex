defmodule Tic.Game do
  alias Tic.Game.{Supervisor, Server}

  def start(game_id) do
    Supervisor.start_child(game_id)
  end

  defdelegate join(game_id), to: Server
  defdelegate leave(game_id, role), to: Server
  defdelegate move(game_id, player, index), to: Server
  defdelegate reset(game_id), to: Server
end
