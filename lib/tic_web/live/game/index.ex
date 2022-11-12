defmodule TicWeb.GameLive.Index do
  use TicWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_event("new", _params, socket) do
    new_game_id = Ecto.UUID.generate()
    {:noreply, push_navigate(socket, to: ~p"/games/#{new_game_id}")}
  end
end
