module ECS
  @[Link(ldflags: "-L#{__DIR__}/../../vendor -lflecs")]
  lib LibECS
    type WorldRef = Void*

    fun init = ecs_init() : WorldRef
    fun fini = ecs_fini(world : WorldRef) : Int32
  end
end
