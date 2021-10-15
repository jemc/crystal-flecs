require "spec"
require "../src/flecs"

# Implicitly set up and tear down the World around each spec example.
# Crystal's Spec doesn't have any way for before/after hooks to set a variable,
# so we unabashedly resort to crude hackery here to get it done for us.
macro it(name, &block)
  it_alias {{name}} do
    world = ECS::World.init

    {{block.body}}

    world.fini
  end
end
# This is a direct copy of how the it method is defined in Spec::Methods.
def it_alias(description = "assert", file = __FILE__, line = __LINE__, end_line = __END_LINE__, focus : Bool = false, tags : String | Enumerable(String) | Nil = nil, &block)
  Spec.root_context.it(description.to_s, file, line, end_line, focus, tags, &block)
end

# To test our DSL, we sometimes need to test which methods have been declared
# by the macros. We use this macro to get the names of the methods of a type.
macro method_names_of(type)
  {{ type.resolve.methods.map(&.name.stringify) }}
end
