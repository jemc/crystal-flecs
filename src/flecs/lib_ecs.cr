@[Link(ldflags: "-L#{__DIR__}/../../vendor -lflecs")]
lib LibECS
  fun ecs_strerror(error_code : Int32) : Pointer(UInt8)
end

# This is just a dummy call for now to force Crystal to add our linker flags,
# just to prove that we can link to the flecs library and invoke it here.
LibECS.ecs_strerror(1)
