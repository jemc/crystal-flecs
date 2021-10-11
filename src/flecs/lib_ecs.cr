module ECS
  @[Link(ldflags: "-L#{__DIR__}/../../vendor -lflecs")]
  lib LibECS
    type WorldRef = Void*
    type ID = UInt64
    type Entity = UInt64

    ECS_MAX_ADD_REMOVE = 32

    struct EntityDesc
      entity : Entity
      name : UInt8*
      sep : UInt8*
      root_sep : UInt8*
      symbol : UInt8*
      use_low_id : Bool
      add : ID[ECS_MAX_ADD_REMOVE]
      add_expr : UInt8*
    end

    fun init = ecs_init() : WorldRef

    fun fini = ecs_fini(world : WorldRef) : Int32

    fun entity_init = ecs_entity_init(
      world : WorldRef,
      desc : EntityDesc*,
    ) : Entity
  end
end
