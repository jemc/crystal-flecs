require "./entity"
require "./component"

module ECS
  def self.builtins_register(world)
    Component.register(world)
    Member.register(world)
  end

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
