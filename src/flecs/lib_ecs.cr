module ECS
  @[Link(ldflags: "-L#{__DIR__}/../../vendor -lflecs")]
  lib LibECS
    type WorldRef = Void*

    ECS_MAX_ADD_REMOVE = 32

    struct EntityDesc
      entity : UInt64
      name : UInt8*
      sep : UInt8*
      root_sep : UInt8*
      symbol : UInt8*
      use_low_id : Bool
      add : UInt64[ECS_MAX_ADD_REMOVE]
      add_expr : UInt8*
    end

    struct ComponentDesc
      entity : EntityDesc
      size : LibC::SizeT
      alignment : LibC::SizeT
    end

    fun init = ecs_init() : WorldRef

    fun fini = ecs_fini(world : WorldRef) : Int32

    fun entity_init = ecs_entity_init(
      world : WorldRef,
      desc : EntityDesc*,
    ) : UInt64

    fun component_init = ecs_component_init(
      world : WorldRef,
      desc : ComponentDesc*,
    ) : UInt64
  end
end
