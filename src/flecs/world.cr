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

  # Get an immutable pointer to a component.
  #
  # This operation obtains a const pointer to the requested component. The
  # operation accepts the component entity id.
  def get_id(entity : UInt64, id : UInt64, c : T.class) forall T
    Pointer(T).new(LibECS.get_id(self, entity, id).address).value
  end

  # Set the value of a component.
  #
  # This operation allows an application to set the value of a component. The
  # operation is equivalent to calling ecs_get_mut and ecs_modified.
  #
  # If the provided entity is 0, a new entity will be created.
  def set_id(entity : UInt64, id : UInt64, c : T) forall T
    LibECS.set_id(self, entity, id, sizeof(T), pointerof(c))
  end

  # Progress a world.
  #
  # This operation progresses the world by running all systems that are both
  # enabled and periodic on their matching entities.
  #
  # An application can pass a delta_time into the function, which is the time
  # passed since the last frame. This value is passed to systems so they can
  # update entity values proportional to the elapsed time since their last
  # invocation.
  #
  # When an application passes 0 to delta_time, ecs_progress will automatically
  # measure the time passed since the last frame. If an application does not uses
  # time management, it should pass a non-zero value for delta_time (1.0 is
  # recommended). That way, no time will be wasted measuring the time.
  #
  # Returns false if ecs_quit has been called, true otherwise.
  def progress(delta_time : Float32 = 0) : Bool
    LibECS.progress(self, delta_time)
  end
end
