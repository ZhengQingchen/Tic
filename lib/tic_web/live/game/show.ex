defmodule TicWeb.GameLive.Show do
  use TicWeb, :live_view

  require Logger
  alias Tic.Game

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    socket = socket |> assign(:game_id, id) |> assign(:role, :unknown)

    if connected?(socket) do
      Game.start(id)

      case Game.join(id) do
        {:ok, role, game} ->
          TicWeb.Endpoint.subscribe("game:" <> id)

          {:ok,
           socket
           |> assign(:role, role)
           |> assign(:game, transform_game(game))}

        {:error, reason} ->
          Logger.info("join game error: #{reason}")
          {:ok, socket}
      end
    else
      {:ok, socket}
    end
  end

  @impl true
  def handle_event("move", %{"index" => index}, socket) do
    {index, ""} = Integer.parse(index)
    %{game_id: game_id, role: role} = socket.assigns

    case Game.move(game_id, role, index) do
      {:ok, new_game} ->
        TicWeb.Endpoint.broadcast("game:" <> game_id, "update_game", new_game)

      {:error, reason} ->
        Logger.info("move error: #{reason}")
        {:error, reason}
    end

    {:noreply, socket}
  end

  def handle_event("reset", _params, socket) do
    game_id = socket.assigns[:game_id]

    case Game.reset(game_id) do
      {:ok, new_game} ->
        TicWeb.Endpoint.broadcast("game:" <> game_id, "update_game", new_game)

      other ->
        Logger.info("can not reset game")
        other
    end

    {:noreply, socket}
  end

  @impl true
  def handle_info(%{payload: game, event: "update_game"}, socket) do
    {:noreply, assign(socket, :game, transform_game(game))}
  end

  @impl true

  def terminate(_reason, socket) do
    role = socket.assigns[:role]

    if role do
      Game.leave(socket.assigns[:game_id], role)
    end

    :ok
  end

  defp transform_game(game) do
    %{game | board: Enum.with_index(game.board)}
  end
end
