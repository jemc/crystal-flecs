require "./entity"
require "./component"

module ECS::Builtins
  ##
  # Core Components

  ECS.extern_component Component do
    ECS_NAME = "Component"
    property size : Int32
    property alignment : Int32
    def initialize(@size, @alignment)
    end
  end

  ##
  # Core Events

  ECS.extern_entity(OnAdd)    { ECS_NAME = "flecs.core.OnAdd" }
  ECS.extern_entity(OnRemove) { ECS_NAME = "flecs.core.OnRemove" }
  ECS.extern_entity(OnSet)    { ECS_NAME = "flecs.core.OnSet" }
  ECS.extern_entity(UnSet)    { ECS_NAME = "flecs.core.UnSet" }
  ECS.extern_entity(OnDelete) { ECS_NAME = "flecs.core.OnDelete" }

  ##
  # Meta Components

  ECS.extern_component Member do
    ECS_NAME = "flecs.meta.Member"
    property type : UInt64
    property count : Int32
    def initialize(@type, @count)
    end
  end

  # Register all of the above builtin entities when we call this function.
  def self.register(world)
    {% for constant in @type.constants %}
      {{ constant }}.register(world)
    {% end %}
  end
end

module ECS
  # Include all Builtins in the ECS scope for easy access, like flecs in C code.
  # For example, EcsComponent in C code translates to ECS::Component here.
  include ECS::Builtins
end
