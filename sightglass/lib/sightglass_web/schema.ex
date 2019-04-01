defmodule GEOF.SightglassWeb.Schema do
  use Absinthe.Schema

  import_types(GEOF.SightglassWeb.Schema.ContentTypes)

  alias GEOF.SightglassWeb.Resolvers

  query do
    @desc "Get a planet’s primal mesh"
    field :planet_field_mesh, :planet_mesh do
      arg(:id, :string, description: "The sphere ID returned after requisitioning a new planet.")
      resolve(&Resolvers.Planet.get_planet_field_mesh/3)
    end

    @desc "Get a planet’s primal wireframe"
    field :planet_field_wireframe, :planet_wireframe do
      arg(:id, :string, description: "The sphere ID returned after requisitioning a new planet.")
      resolve(&Resolvers.Planet.get_planet_field_wireframe/3)
    end

    @desc "Get a planet’s dual wireframe"
    field :planet_interfield_wireframe, :planet_wireframe do
      arg(:id, :string, description: "The sphere ID returned after requisitioning a new planet.")
      resolve(&Resolvers.Planet.get_planet_interfield_wireframe/3)
    end
  end

  mutation do
    @desc "Requisition a new planet"
    field :create_planet, :planet do
      arg(:divisions, :integer)
      resolve(&Resolvers.Planet.create_planet/3)
    end

    @desc "Compute a frame of the simulation"
    field :compute_frame, :frame do
      arg(:id, :string, description: "The sphere ID returned after requisitioning a new planet.")
      arg(:iterator, :string, description: "The iterator function to run for each field.")
      resolve(&Resolvers.Planet.compute_frame/3)
    end
  end
end
