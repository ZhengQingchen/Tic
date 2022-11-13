defmodule TicWeb.GameLive.BoardComponent do
  use TicWeb, :live_component

  @impl true
  def render(assigns) do
    ~H"""
    <div class="flex flex-row flex-wrap w-96 text-5xl">
      <%= for {item, index} <- Enum.with_index(@board) do %>
        <div
          phx-click="move"
          phx-value-index={index}
          class={"flex items-center content-center w-1/3 h-32 border-4 #{if index in @win_path, do: "bg-red-500"}"}
        >
          <%= if is_binary(item) do %>
            <div class="w-full text-center">
              <%= item %>
            </div>
          <% end %>
        </div>
      <% end %>
    </div>
    """
  end
end
