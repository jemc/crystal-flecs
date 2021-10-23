require "./entity"
require "./component"

module ECS
  # TODO: Auto-register all builtins using a macro that scans the list of
  # all constants defined in ECS::Builtin, then include ECS::Builtin
  def self.builtins_register(world)
    OnAdd.register(world)
    OnRemove.register(world)
    Component.register(world)
    Member.register(world)
  end

  ECS.builtin_entity(OnAdd) { ECS_NAME = "flecs.core.OnAdd" }
  ECS.builtin_entity(OnRemove) { ECS_NAME = "flecs.core.OnRemove" }

  ECS.builtin_component Component do
    ECS_NAME = "Component"
    property size : Int32
    property alignment : Int32
    def initialize(@size, @alignment)
    end
  end

  ECS.builtin_component Member do
    ECS_NAME = "flecs.meta.Member"
    property type : UInt64
    property count : Int32
    def initialize(@type, @count)
    end
  end
end
