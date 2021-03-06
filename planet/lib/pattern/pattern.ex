defmodule GEOF.Planet.Pattern do
  alias GEOF.Planet.{
    Sphere,
    Geometry.FieldCentroids
  }

  @moduledoc """
    Functions for producing colors across the sphere model.
  """

  ###
  #
  # TYPES
  #
  ###

  @typedoc "A basic RGB color."

  @type color :: {:rgb, non_neg_integer, non_neg_integer, non_neg_integer}

  @typedoc "Maps Field indexes to RGB colors."

  @type frame :: %{GEOF.Planet.Field.index() => color}

  ###
  #
  # FUNCTIONS
  #
  ###

  ###
  # Highlight icosahedron
  ###

  @highlight_icosahedron_c1 {:rgb, 228, 234, 192}
  @highlight_icosahedron_c2 {:rgb, 166, 206, 146}

  @doc "Highlights Fields along the edges of the icosahedron."

  @spec highlight_icosahedron(Sphere.divisions()) :: frame

  def highlight_icosahedron(divisions) do
    Sphere.for_all_fields(%{}, divisions, fn acc, index ->
      Map.put(acc, index, highlight_icosahedron_on_field(index, divisions))
    end)
  end

  defp highlight_icosahedron_on_field(:north, _), do: @highlight_icosahedron_c2
  defp highlight_icosahedron_on_field(:south, _), do: @highlight_icosahedron_c2

  defp highlight_icosahedron_on_field({:sxy, _s, x, y}, d) do
    cond do
      rem(x + y + 1, d) == 0 or rem(x + 1, d) == 0 or y == 0 ->
        @highlight_icosahedron_c2

      true ->
        @highlight_icosahedron_c1
    end
  end

  ###
  # Tetrahedron
  ###

  @tetrahedron_colors %{
    0 => {:rgb, 235, 246, 247},
    1 => {:rgb, 152, 189, 174},
    2 => {:rgb, 200, 221, 228},
    3 => {:rgb, 134, 171, 165},
    nil => {:rgb, 23, 20, 18}
  }

  @doc "Highlights the panels of a Sphere divided by a tetrahedron."

  @spec tetrahedron(Sphere.divisions()) :: frame

  def tetrahedron(divisions) do
    centroid_sphere = FieldCentroids.field_centroids(divisions)

    Sphere.for_all_fields(%{}, divisions, fn acc, field_index ->
      Map.put(acc, field_index, tetrahedron(centroid_sphere, field_index))
    end)
  end

  defp tetrahedron(centroid_sphere, field_index) do
    Map.get(
      @tetrahedron_colors,
      GEOF.Shapes.face_of_4_hedron(Map.get(centroid_sphere, field_index))
    )
  end

  ###
  # Octahedron
  ###

  @octahedron_colors %{
    0 => {:rgb, 68, 147, 187},
    1 => {:rgb, 79, 68, 187},
    2 => {:rgb, 167, 68, 187},
    3 => {:rgb, 187, 68, 117},
    4 => {:rgb, 187, 108, 68},
    5 => {:rgb, 176, 187, 68},
    6 => {:rgb, 88, 187, 68},
    7 => {:rgb, 68, 187, 138},
    nil => {:rgb, 23, 20, 18}
  }

  @doc "Highlights the panels of a Sphere divided by an octahedron."

  @spec octahedron(Sphere.divisions()) :: frame

  def octahedron(divisions) do
    centroid_sphere = FieldCentroids.field_centroids(divisions)

    Sphere.for_all_fields(%{}, divisions, fn acc, field_index ->
      Map.put(acc, field_index, octahedron(centroid_sphere, field_index))
    end)
  end

  defp octahedron(centroid_sphere, field_index) do
    Map.get(
      @octahedron_colors,
      GEOF.Shapes.face_of_8_hedron(Map.get(centroid_sphere, field_index))
    )
  end
end
