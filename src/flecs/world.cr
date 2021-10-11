struct ECS::World
  @unsafe : LibECS::WorldRef
  def to_unsafe; @unsafe end
  def initialize(@unsafe)
  end

  # Create a new world.
  #
  # A world manages all the ECS data and supporting infrastructure. Applications
  # must have at least one world. Entities, component and system handles are
  # local to a world and should not be shared between worlds.
  #
  # This operation creates a world with all builtin modules loaded.
  def self.init
    new(LibECS.init)
  end

  # Delete a world.
  #
  # This operation deletes the world, and everything it contains.
  def fini
    raise Error.new("Failed to destroy the given world") \
      unless 0 == LibECS.fini(self)
  end

  # Find or create an entity.
  #
  # This operation creates a new entity, or modifies an existing one. When a name
  # is set in the ecs_entity_desc_t::name field and ecs_entity_desc_t::entity is
  # not set, the operation will first attempt to find an existing entity by that
  # name. If no entity with that name can be found, it will be created.
  #
  # If both a name and entity handle are provided, the operation will check if
  # the entity name matches with the provided name. If the names do not match,
  # the function will fail and return 0.
  #
  # If an id to a non-existing entity is provided, that entity id become alive.
  #
  # See the documentation of ecs_entity_desc_t for more details.
  def entity_init(
    name : String? = nil,
    add_expr : String? = nil,
  ) : UInt64
    desc = LibECS::EntityDesc.new
    desc.name = name if name
    desc.add_expr = add_expr if add_expr

    id = LibECS.entity_init(self, pointerof(desc))

    raise Error.new("Failed to initialize entity") \
      if id == 0

    id
  end

  # Find or create a component.
  #
  # This operation creates a new component, or finds an existing one. The find or
  # create behavior is the same as ecs_entity_init.
  #
  # When an existing component is found, the size and alignment are verified with
  # the provided values. If the values do not match, the operation will fail.
  #
  # See the documentation of ecs_component_desc_t for more details.
  def component_init(
    name : String? = nil,
    add_expr : String? = nil,
    size : Int32? = nil,
    alignment : Int32? = nil,
  ) : UInt64
    desc = LibECS::ComponentDesc.new
    desc.entity.name = name if name
    desc.entity.add_expr = add_expr if add_expr
    desc.size = size if size
    desc.alignment = alignment if alignment

    id = LibECS.component_init(self, pointerof(desc))

    raise Error.new("Failed to initialize component") \
      if id == 0

    id
  end
end