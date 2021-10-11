struct ECS::World
  # This is our internal mutable state container for the world, where we will
  # put anything we need to access from Crystal which isn't in flecs.
  #
  # In it, we can store the equivalent of global variables as properties.
  #
  # These properties are not truly global because each World has its own Root.
  # The properties will be defined in other files, often from within macros.
  class Root
  end

  @unsafe : LibECS::WorldRef
  protected getter root : ECS::World::Root
  def to_unsafe; @unsafe end
  def initialize(@unsafe, @root)
  end

  # Create a new world.
  #
  # A world manages all the ECS data and supporting infrastructure. Applications
  # must have at least one world. Entities, component and system handles are
  # local to a world and should not be shared between worlds.
  #
  # This operation creates a world with all builtin modules loaded.
  def self.init
    new(LibECS.init, Root.new)
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

  # Get an immutable pointer to a component.
  #
  # This operation obtains a const pointer to the requested component. The
  # operation accepts the component entity id.
  def get_id(entity : UInt64, id : UInt64, c : T.class) forall T
    Pointer(T).new(LibECS.get_id(self, entity, id).address).value
  end

  # Convenience wrapper for get_id for when component implements the id method.
  def get(entity : UInt64, component_class : T.class) forall T
    get_id(entity, component_class.id(self), component_class)
  end

  # Convenience wrapper for get for when the entity is a component singleton.
  def get_singleton(component_class : T.class) forall T
    get_id(component_class.id(self), component_class.id(self), component_class)
  end

  # Set the value of a component.
  #
  # This operation allows an application to set the value of a component. The
  # operation is equivalent to calling ecs_get_mut and ecs_modified.
  #
  # If the provided entity is 0, a new entity will be created.
  def set_id(entity : UInt64, id : UInt64, component : T) : T forall T
    LibECS.set_id(self, entity, id, sizeof(T), pointerof(component))
    component
  end

  # Convenience wrapper for set_id for when component implements the id method.
  def set(entity : UInt64, component : T) : T forall T
    set_id(entity, component.class.id(self), component)
  end

  # Convenience wrapper for set for when the entity is a component singleton.
  def set_singleton(component : T) : T forall T
    set(component.class.id(self), component)
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
