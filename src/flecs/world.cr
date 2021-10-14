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

  # Get world info.
  def info : LibECS::WorldInfo
    LibECS.get_world_info(self).value
  end

  # Set target frames per second (FPS) for application.
  #
  # Setting the target FPS ensures that ecs_progress is not invoked faster than
  # the specified FPS. When enabled, ecs_progress tracks the time passed since
  # the last invocation, and sleeps the remaining time of the frame (if any).
  #
  # This feature ensures systems are ran at a consistent interval, as well as
  # conserving CPU time by not running systems more often than required.
  #
  # Note that ecs_progress only sleeps if there is time left in the frame. Both
  # time spent in flecs as time spent outside of flecs are taken into
  # account.
  def target_fps=(value)
    LibECS.set_target_fps(self, value)
  end

  # Get target frames per second (FPS) for application.
  #
  # See the setter method for more details on how this value is used.
  def target_fps
    info.target_fps
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

  # Lookup an entity by name.
  #
  # Returns an entity that matches the specified name. Only looks for entities in
  # the current scope (root if no scope is provided).
  #
  # Returns the entity with the specified name, or nil if no entity was found.
  def lookup(name : String) : UInt64?
    id = LibECS.lookup(self, name)
    id if id != 0
  end

  # Get an immutable pointer to a component.
  #
  # This operation obtains a const pointer to the requested component. The
  # operation accepts the component entity id.
  def get_id(entity : UInt64, id : UInt64, c : T.class): T? forall T
    ptr = Pointer(T).new(LibECS.get_id(self, entity, id).address)
    ptr.value unless ptr.null?
  end

  # Convenience wrapper for get_id for when component implements the id method.
  def get(entity : UInt64, component_class : T.class) forall T
    get_id(entity, component_class.id(self), component_class)
  end

  # Convenience wrapper for get for when the entity is a component singleton.
  def get_singleton(component_class : T.class) forall T
    get_id(component_class.id(self), component_class.id(self), component_class)
  end

  # Get a component that relates a subject entity to an object entity
  def get_relation(entity : UInt64, component_class : T.class, object : UInt64) forall T
    relation = LibECS.make_pair(component_class.id(self), object)
    get_id(entity, relation, component_class)
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
  def set(entity : UInt64, component : T) forall T
    set_id(entity, component.class.id(self), component)
  end

  # Convenience wrapper for set for when the entity is a component singleton.
  def set_singleton(component : T) forall T
    set(component.class.id(self), component)
  end

  # Set a component that relates a subject entity to an object entity.
  def set_relation(subject : UInt64, component : T, object : UInt64) forall T
    relation = LibECS.make_pair(component.class.id(self), object)
    set_id(subject, relation, component)
  end

  # Remove an entity from an entity.
  #
  # This operation removes a single entity from the type of an entity. Type roles
  # may be used in combination with the added entity. If the entity does not have
  # the entity, this operation will have no side effects.
  def remove_id(entity : UInt64, id : UInt64) forall T
    LibECS.remove_id(self, entity, id)
    nil
  end

  # Convenience wrapper for remove_id for when component implements the id method.
  def remove(entity : UInt64, component_class : T.class) forall T
    remove_id(entity, component_class.id(self))
  end

  # Convenience wrapper for remove for when the entity is a component singleton.
  def remove_singleton(component_class : T.class) forall T
    remove(component_class.id(self), component_class)
  end

  # Remove a component if it relates the subject entity to the object entity.
  def remove_relation(subject : UInt64, component_class : T.class, object : UInt64) forall T
    relation = LibECS.make_pair(component_class.id(self), object)
    remove_id(subject, relation)
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
