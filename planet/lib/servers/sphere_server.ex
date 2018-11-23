defmodule GEOF.Planet.SphereServer do
  use GenServer

  alias GEOF.Planet.Geometry.FieldCentroids
  alias GEOF.Planet.Geometry.InterfieldCentroids
  alias GEOF.Planet.PanelSupervisor
  alias GEOF.Planet.PanelServer
  alias GEOF.Planet.Registry
  alias GEOF.Planet.Sphere
  alias GEOF.Shapes

  # ~~~
  # Naming conventions:
  #
  # In `planet/lib/servers`, the names `panel` and `field` are equivalent to `panel_index` and
  # `field_index` (respectively) for the sake of brevity. The data belonging to a field is always
  # `field_data`, and a group of such data is `sphere_data`, whether it's data for just part of
  # the sphere or for the entire sphere.
  #
  # In the servers' APIs, `get` is always a call, and `request` and `send` are always casts.
  # ~~~

  ###
  #
  # Types
  #
  ###

  @type sphere_id :: reference

  @type panel_index :: non_neg_integer

  @type sphere_data :: %{GEOF.Planet.Field.index() => any}

  @type fields :: MapSet.t(GEOF.Planet.Field.index())

  @type fields_at_panels :: %{panel_index => fields}

  @type fn_ref :: {module(), function_name :: atom}

  @type sphere :: %{
          :id => reference,
          :divisions => Sphere.divisions(),
          :field_centroids => FieldCentroids.centroid_sphere(),
          :interfield_centroids => InterfieldCentroids.interfield_centroid_sphere(),
          :fields_at_panels => fields_at_panels,
          :n_panels => non_neg_integer
        }

  ###
  #
  # API
  #
  ###

  @spec start_link(Sphere.divisions(), sphere_id) :: GenServer.on_start()

  def start_link(divisions, sphere_id) do
    GenServer.start_link(__MODULE__, [divisions, sphere_id],
      name: Registry.sphere_via_reg(sphere_id)
    )
  end

  @spec get_all_field_data(sphere_id) :: sphere_data

  def get_all_field_data(sphere_id) do
    GenServer.call(Registry.sphere_via_reg(sphere_id), :get_all_field_data)
  end

  @spec start_frame(sphere_id, fn_ref, pid) :: :ok

  def start_frame(sphere_id, {module_name, function_name}, from) do
    #    IO.puts("[sphere] start_frame")
    per_field = {
      String.to_existing_atom("Elixir.#{module_name}"),
      String.to_existing_atom(function_name)
    }

    GenServer.cast(Registry.sphere_via_reg(sphere_id), {:start_frame, per_field, from})
  end

  ###
  #
  # Server
  #
  ###

  ###
  # Utility
  ###

  @impl true
  def init([divisions, sphere_id]) do
    sphere = init_sphere(divisions, sphere_id)

    {:ok, panel_supervisor} = PanelSupervisor.start_link(sphere)

    {:ok,
     %{
       sphere: sphere,
       panel_supervisor: panel_supervisor,
       in_frame: false
     }}
  end

  @spec init_sphere(Sphere.divisions(), sphere_id) :: sphere

  def init_sphere(divisions, sphere_id) do
    field_centroids = FieldCentroids.field_centroids(divisions)
    interfield_centroids = InterfieldCentroids.interfield_centroids(field_centroids, divisions)

    sphere = %{
      id: sphere_id,
      divisions: divisions,
      field_centroids: field_centroids,
      interfield_centroids: interfield_centroids
    }

    fields_at_panels = init_fields_at_panels(sphere)

    #    IO.puts("[sphere] fields at panels")
    #    IO.inspect(fields_at_panels)

    Map.merge(sphere, %{
      fields_at_panels: fields_at_panels,
      n_panels: length(Map.keys(fields_at_panels))
    })
  end

  @impl true
  def handle_call(:get_all_field_data, _from, state) do
    {:reply,
     Enum.reduce(Map.keys(state.sphere.fields_at_panels), %{}, fn panel_index, all_data ->
       panel_data = PanelServer.get_all_field_data(state.sphere.id, panel_index)

       Map.merge(
         all_data,
         panel_data
       )
     end), state}
  end

  ###
  # Panel computation
  ###

  # `init_fields_at_panels` Creates a `fields_at_panels` mapping panel indexes to the field
  # indexes that belong to that panel. Panels are formed by splitting the sphere into a number of
  # parts based on the available threads and efficient perimeter-minimizing geometries.

  defp init_fields_at_panels(sphere, n) when n == 4 do
    Sphere.for_all_fields(init_fields_at_panels(n), sphere.divisions, fn fields_at_panels,
                                                                         field_index ->
      panel_index_for_field = Shapes.face_of_4_hedron(sphere.field_centroids[field_index])

      update_in(
        fields_at_panels[panel_index_for_field],
        &MapSet.put(&1, field_index)
      )
    end)
  end

  defp init_fields_at_panels(sphere, n) when n == 8 do
    Sphere.for_all_fields(init_fields_at_panels(n), sphere.divisions, fn fields_at_panels,
                                                                         field_index ->
      panel_index_for_field = Shapes.face_of_8_hedron(sphere.field_centroids[field_index])

      update_in(
        fields_at_panels[panel_index_for_field],
        &MapSet.put(&1, field_index)
      )
    end)
  end

  defp init_fields_at_panels(n) when is_integer(n) do
    Enum.reduce(0..(n - 1), %{}, fn panel_index, fields_at_panels ->
      Map.put(fields_at_panels, panel_index, MapSet.new())
    end)
  end

  @spec init_fields_at_panels(sphere) :: fields_at_panels

  defp init_fields_at_panels(sphere) do
    threads = :erlang.system_info(:schedulers_online)

    cond do
      threads >= 8 -> init_fields_at_panels(sphere, 8)
      threads > 0 -> init_fields_at_panels(sphere, 4)
    end
  end

  ###
  # Frames
  ###

  @impl true
  def handle_cast({:start_frame, per_field, from}, state) do
    state = Map.put(state, :__reply_to__, from)

    Enum.each(Map.keys(state.sphere.fields_at_panels), fn panel_index ->
      PanelServer.start_frame(
        state.sphere.id,
        panel_index,
        per_field
      )
    end)

    state =
      Map.merge(state, %{
        __panels_ready_to_commit__: MapSet.new(),
        in_frame: true
      })

    {:noreply, state}
  end

  @impl true
  def handle_cast({:__ready_to_commit_frame__, panel_index}, state) do
    #    IO.puts("[sphere] __ready_to_commit_frame__: #{panel_index}")

    state =
      update_in(
        state.__panels_ready_to_commit__,
        &MapSet.put(&1, panel_index)
      )

    if ready_to_commit_frame?(state), do: GenServer.cast(self(), :__commit_frame__)
    {:noreply, state}
  end

  @impl true
  def handle_cast(:__commit_frame__, state) do
    #    IO.puts("[sphere] __commit_frame__")

    Enum.each(Map.keys(state.sphere.fields_at_panels), fn panel_index ->
      PanelServer.commit_frame(
        state.sphere.id,
        panel_index
      )
    end)

    if is_pid(state.__reply_to__), do: send(state.__reply_to__, :frame_complete)
    {:noreply, state}
  end

  defp ready_to_commit_frame?(state) do
    MapSet.size(state.__panels_ready_to_commit__) == state.sphere.n_panels
  end
end
