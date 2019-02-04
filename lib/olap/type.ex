defmodule Olap.Type do
  alias Olap.FieldSet.Field
  alias Olap.Cube.Dimension.HierarchyLevel

  @type settings :: map()

  @callback build_settings(spec :: map()) :: {:ok, settings} | {:error, term()}
  @callback validate(settings :: settings, value :: term()) :: :ok | {:error, term()}

  @callback parse_string(settings :: settings, str :: bitstring()) ::
              {:ok, term()} | {:error, term()}

  @callback parse_hierarchy_level_value(
              field :: Field,
              str :: bitstring(),
              previous_levels :: [HierarchyLevel]
            ) :: {:ok, term(), Field} | {:error, term()}

  @callback get_coordinate(settings :: settings, value :: term(), hierarchy :: [HierarchyLevel]) ::
              [term()]

  @optional_callbacks [build_settings: 1]
end
