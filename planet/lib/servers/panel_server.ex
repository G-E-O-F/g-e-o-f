defmodule GEOF.Planet.PanelServer do
  use GenServer
  import GEOF.Planet.Registry

  # API

  def start_link(sphere, panel_index, field_set) do
    GenServer.start_link(__MODULE__, [sphere, panel_index, field_set],
      name: panel_via_reg(sphere, panel_index)
    )
  end

  #  def get_data(sphere_id, index) do
  #    GenServer.call(field_via_reg(sphere_id, index), :get_data)
  #  end

  def get_state(sphere, panel_index) do
    GenServer.call(panel_via_reg(sphere, panel_index), :get_state)
  end

  #  def iterate(sphere_id, index, module_name, func_name) do
  #    GenServer.cast(field_via_reg(sphere_id, index), {:iterate, module_name, func_name})
  #  end

  #  def finish_iteration(sphere_id, index) do
  #    GenServer.cast(field_via_reg(sphere_id, index), :finish_iteration)
  #  end

  # SERVER

  @impl true
  def init([sphere, panel_index, field_set]) do
    {:ok,
     %{
       id: {Map.get(sphere, :id), panel_index},
       field_set: field_set,
       data: nil
     }}
  end

  #  @impl true
  #  def handle_cast(:finish_iteration, state) do
  #    {:noreply, Map.put(state, :data, Map.get(state, :next)) |> Map.delete(:next)}
  #  end

  #  @impl true
  #  def handle_cast({:iterate, module_name, func_name}, state) do
  #    # Applies an arbitrary module's function with the current and adjacent fields' state
  #    {:noreply,
  #     Map.put(
  #       state,
  #       :next,
  #       apply(
  #         String.to_existing_atom("Elixir.#{module_name}"),
  #         func_name,
  #         [state, get_adjacents_data(state)]
  #       )
  #     )}
  #  end

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  #  @impl true
  #  def handle_call(:get_data, _from, state) do
  #    {:reply, Map.get(state, :data), state}
  #  end
end