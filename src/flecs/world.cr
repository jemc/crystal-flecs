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
  protected getter root : World::Root
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
    world = new(LibECS.init, Root.new)

    ECS.builtins_register(world)

    world
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

  # Set the current scope, temporarily.
  #
  # This operation sets the scope of the current stage to the provided entity.
  # As a result new entities will be created in this scope, and lookups will be
  # relative to the provided scope.
  #
  # Restore the scope to the old value after the block is done.
  def in_scope(entity)
    entity = entity.id(self) unless entity.is_a?(UInt64)
    old_scope_entity = LibECS.set_scope(self, entity)

    yield

    LibECS.set_scope(self, old_scope_entity)
    nil
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

  def lookup_fullpath(path : String) : UInt64?
    id = LibECS.lookup_path_w_sep(self, 0_u64, path, ".", nil, true)
    id if id != 0
  end

  # Get an immutable pointer to a component.
  #
  # This operation obtains a const pointer to the requested component. The
  # operation accepts the component entity id.
  def get_id(entity, id : UInt64, c : T.class): T? forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    ptr = Pointer(T).new(LibECS.get_id(self, entity, id).address)
    ptr.value unless ptr.null?
  end

  # Convenience wrapper for get_id for when component implements the id method.
  def get(entity, component_class : T.class) forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    get_id(entity, component_class.id(self), component_class)
  end

  # Convenience wrapper for get for when the entity is a component singleton.
  def get_singleton(component_class : T.class) forall T
    get_id(component_class.id(self), component_class.id(self), component_class)
  end

  # Get a component that relates a subject entity to an object entity
  def get_relation(subject, component_class : T.class, object) forall T
    subject = subject.id(self) unless subject.is_a?(UInt64)
    object = object.id(self) unless object.is_a?(UInt64)
    relation = LibECS.make_pair(component_class.id(self), object)
    get_id(subject, relation, component_class)
  end

  # Set the value of a component.
  #
  # This operation allows an application to set the value of a component. The
  # operation is equivalent to calling ecs_get_mut and ecs_modified.
  #
  # If the provided entity is 0, a new entity will be created.
  def set_id(entity, id : UInt64, component : T) : T forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    LibECS.set_id(self, entity, id, sizeof(T), pointerof(component))
    component
  end

  # Convenience wrapper for set_id for when component implements the id method.
  def set(entity, component : T) forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    set_id(entity, component.class.id(self), component)
  end

  # Convenience wrapper for set for when the entity is a component singleton.
  def set_singleton(component : T) forall T
    set(component.class.id(self), component)
  end

  # Set a component that relates a subject entity to an object entity.
  def set_relation(subject, component : T, object) forall T
    subject = subject.id(self) unless subject.is_a?(UInt64)
    object = object.id(self) unless object.is_a?(UInt64)
    relation = LibECS.make_pair(component.class.id(self), object)
    set_id(subject, relation, component)
  end

  # Remove an entity from an entity.
  #
  # This operation removes a single entity from the type of an entity. Type roles
  # may be used in combination with the added entity. If the entity does not have
  # the entity, this operation will have no side effects.
  def remove_id(entity, id : UInt64) forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    LibECS.remove_id(self, entity, id)
    nil
  end

  # Convenience wrapper for remove_id for when component implements the id method.
  def remove(entity, component_class : T.class) forall T
    entity = entity.id(self) unless entity.is_a?(UInt64)
    remove_id(entity, component_class.id(self))
  end

  # Convenience wrapper for remove for when the entity is a component singleton.
  def remove_singleton(component_class : T.class) forall T
    remove(component_class.id(self), component_class)
  end

  # Remove a component if it relates the subject entity to the object entity.
  def remove_relation(subject, component_class : T.class, object) forall T
    subject = subject.id(self) unless subject.is_a?(UInt64)
    object = object.id(self) unless object.is_a?(UInt64)
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

  # Add brief description to entity.
  #
  # Please ensure that the String is a String literal,
  # or that it is retained somewhere traceable from Crystal,
  # because otherwise the buffer may be garbage-collected,
  # leading to memory corruption.
  #
  # TODO: Some way to enforce this?
  # Maybe with a macro that enforces StringLiteral?
  def doc_set_brief(entity, description : String)
    entity = entity.id(self) unless entity.is_a?(UInt64)
    LibECS.doc_set_brief(self, entity, description)
    description
  end

  # Add detailed description to entity.
  #
  # Please ensure that the String is a String literal,
  # or that it is retained somewhere traceable from Crystal,
  # because otherwise the buffer may be garbage-collected,
  # leading to memory corruption.
  #
  # TODO: Some way to enforce this?
  # Maybe with a macro that enforces StringLiteral?
  def doc_set_detail(entity, description : String)
    entity = entity.id(self) unless entity.is_a?(UInt64)
    LibECS.doc_set_detail(self, entity, description)
    description
  end

  # Add link to external documentation to entity.
  #
  # Please ensure that the String is a String literal,
  # or that it is retained somewhere traceable from Crystal,
  # because otherwise the buffer may be garbage-collected,
  # leading to memory corruption.
  #
  # TODO: Some way to enforce this?
  # Maybe with a macro that enforces StringLiteral?
  def doc_set_link(entity, link : String)
    entity = entity.id(self) unless entity.is_a?(UInt64)
    LibECS.doc_set_link(self, entity, link)
    link
  end

  # Get brief description from entity.
  #
  # Performance warning: a new String object is allocated,
  # along with a new buffer that copies the docs from the original buffer,
  # because Crystal doesn't want to create a String that shares the memory.
  def doc_get_brief(entity) : String?
    entity = entity.id(self) unless entity.is_a?(UInt64)
    ptr = LibECS.doc_get_brief(self, entity)
    String.new(ptr) unless ptr.null?
  end

  # Get detailed description from entity.
  #
  # Performance warning: a new String object is allocated,
  # along with a new buffer that copies the docs from the original buffer,
  # because Crystal doesn't want to create a String that shares the memory.
  def doc_get_detail(entity) : String?
    entity = entity.id(self) unless entity.is_a?(UInt64)
    ptr = LibECS.doc_get_detail(self, entity)
    String.new(ptr) unless ptr.null?
  end

  # Get link to external documentation from entity.
  #
  # Performance warning: a new String object is allocated,
  # along with a new buffer that copies the docs from the original buffer,
  # because Crystal doesn't want to create a String that shares the memory.
  def doc_get_link(entity) : String?
    entity = entity.id(self) unless entity.is_a?(UInt64)
    ptr = LibECS.doc_get_link(self, entity)
    String.new(ptr) unless ptr.null?
  end

  # For meta purposes, we want to be able to represent any member type
  # from a Crystal component as an entity id in flecs.
  def ecs_type_from_crystal_member_type(t) : UInt64
    case t
    when Bool           .class then LibECS.bool_t
    when UInt8          .class then LibECS.u8_t
    when UInt16         .class then LibECS.u16_t
    when UInt32         .class then LibECS.u32_t
    when UInt64         .class then LibECS.u64_t
    when LibC::SizeT    .class then LibECS.uptr_t
    when Int8           .class then LibECS.i8_t
    when Int16          .class then LibECS.i16_t
    when Int32          .class then LibECS.i32_t
    when Int64          .class then LibECS.i64_t
    when Float32        .class then LibECS.f32_t
    when Float64        .class then LibECS.f64_t
    when Pointer(UInt8) .class then LibECS.string_t
    else                            LibECS.uptr_t
    # TODO: Handle embedded structs
    # TODO: Disallow classes, due to GC concerns?
    end
  end
end
