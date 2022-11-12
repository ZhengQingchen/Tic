defmodule Tic.Game.Server do
  use GenServer

  @registry :game_registry
  @roles ["x", "o"]

  defmodule Tic.Game.Server.State do
    defstruct [
      :game_id,
      :pending_roles,
      :status,
      :board,
      :active_player,
      :mode,
      :winner,
      :win_path
    ]
  end

  def default_state(game_id, pending_roles \\ @roles) do
    %Tic.Game.Server.State{
      game_id: game_id,
      pending_roles: pending_roles,
      board: [0, 1, 2, 3, 4, 5, 6, 7, 8],
      status: :pending,
      winner: nil,
      win_path: [],
      active_player: "x"
    }
  end

  def start_link(game_id) do
    GenServer.start_link(__MODULE__, default_state(game_id), name: via_tuple(game_id))
  end

  def state(game_id) do
    GenServer.call(via_tuple(game_id), :state)
  end

  def join(game_id) do
    GenServer.call(via_tuple(game_id), :join)
  end

  def leave(game_id, role) do
    GenServer.call(via_tuple(game_id), {:leave, role})
  end

  def move(game_id, player, index) do
    GenServer.call(via_tuple(game_id), {:move, player, index})
  end

  def reset(game_id) do
    GenServer.call(via_tuple(game_id), :reset)
  end

  @impl true
  def init(state) do
    {:ok, state}
  end

  @impl true

  def handle_call(:state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:reset, _from, %{game_id: game_id, pending_roles: pending_roles}) do
    new_state = default_state(game_id, pending_roles)
    {:reply, {:ok, new_state}, new_state}
  end

  def handle_call(:join, _from, %{pending_roles: [role | rest]} = state) do
    new_state = %{state | pending_roles: rest}
    {:reply, {:ok, role, new_state}, new_state}
  end

  def handle_call(:join, _from, %{} = state) do
    {:reply, {:error, :can_not_join}, state}
  end

  def handle_call({:leave, role}, _from, %{pending_roles: pending_roles} = state) do
    if role in pending_roles do
      {:reply, :ok, state}
    else
      pending_roles = [role | pending_roles]
      new_state = %{state | pending_roles: pending_roles}

      if length(pending_roles) == 2 do
        {:stop, :normal, :ok, new_state}
      else
        {:reply, :ok, new_state}
      end
    end
  end

  def handle_call(
        {:move, player, index},
        _from,
        %{active_player: player, board: board, status: :pending} = state
      ) do
    case Enum.at(board, index) do
      value when is_number(value) ->
        new_board = List.replace_at(board, index, player)
        new_player = switch_player(player)

        {status, winner, win_path} =
          case check_status(new_board) do
            :pending -> {:pending, nil, []}
            :draw -> {:draw, nil, []}
            {:win, winner, win_path} -> {:win, winner, win_path}
          end

        new_state = %{
          state
          | board: new_board,
            active_player: new_player,
            status: status,
            winner: winner,
            win_path: win_path
        }

        {:reply, {:ok, new_state}, new_state}

      _other ->
        {:reply, {:error, :duplicated_move}, state}
    end
  end

  def handle_call({:move, _player, _index}, _from, %{status: :pending} = state) do
    {:reply, {:error, :not_your_turn}, state}
  end

  def handle_call({:move, _player, _index}, _from, state) do
    {:reply, {:error, :game_ended}, state}
  end

  defp switch_player("x"), do: "o"
  defp switch_player("o"), do: "x"

  @spec check_status(list()) :: :draw | :pending | {:win, binary(), list()}

  for player <- ["x", "o"] do
    def check_status([unquote(player), unquote(player), unquote(player), _, _, _, _, _, _]),
      do: {:win, unquote(player), [0, 1, 2]}

    def check_status([_, _, _, unquote(player), unquote(player), unquote(player), _, _, _]),
      do: {:win, unquote(player), [3, 4, 5]}

    def check_status([_, _, _, _, _, _, unquote(player), unquote(player), unquote(player)]),
      do: {:win, unquote(player), [6, 7, 8]}

    def check_status([unquote(player), _, _, unquote(player), _, _, unquote(player), _, _]),
      do: {:win, unquote(player), [0, 3, 6]}

    def check_status([_, unquote(player), _, _, unquote(player), _, _, unquote(player), _]),
      do: {:win, unquote(player), [1, 4, 7]}

    def check_status([_, _, unquote(player), _, _, unquote(player), _, _, unquote(player)]),
      do: {:win, unquote(player), [2, 5, 8]}

    def check_status([unquote(player), _, _, _, unquote(player), _, _, _, unquote(player)]),
      do: {:win, unquote(player), [0, 4, 8]}

    def check_status([_, _, unquote(player), _, unquote(player), _, unquote(player), _, _]),
      do: {:win, unquote(player), [2, 4, 6]}
  end

  def check_status(state) do
    if Enum.all?(state, &is_binary/1) do
      :draw
    else
      :pending
    end
  end

  defp via_tuple(name),
    do: {:via, Registry, {@registry, name}}
end
