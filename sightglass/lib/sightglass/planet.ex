defmodule GEOF.Sightglass.Planet do
  def get_planet(divisions) do
    mesh = GEOF.Planet.Geometry.Mesh.poly_per_field(divisions)

    %{
      id: divisions,
      divisions: divisions,
      mesh: %{
        position: mesh[:position],
        normal: mesh[:normal],
        index: mesh[:index],
        vertex_order: mesh[:vertex_order]
      }
    }
  end

  def get_planet_edges(divisions) do
    edge_mesh = GEOF.Planet.Geometry.EdgeMesh.poly_per_field(divisions)

    %{
      id: divisions,
      divisions: divisions,
      wireframe: %{
        position: edge_mesh[:position],
        index: edge_mesh[:index]
      }
    }
  end

  def get_planet_frame(divisions, pattern) do
    # This is just example stuff for now.
    frame_colors = GEOF.Planet.Pattern.tetrahedron(divisions)

    %{
      id: "#{divisions}:#{pattern}",
      divisions: divisions,
      pattern: pattern,
      colors:
        Enum.reduce(frame_colors, %{}, fn {index, {:rgb, r, g, b}}, acc ->
          Map.put(acc, GEOF.Planet.Field.flatten_index(index, divisions), [r, g, b])
        end)
    }
  end
end
