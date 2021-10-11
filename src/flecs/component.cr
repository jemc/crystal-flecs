macro component(name, &block)
  struct {{name}}
    extend ECS::Component::StaticMethods
    include ECS::Component::DSL
    _dsl_begin
    {{block.body}}
    _dsl_end({{name}})
  end
end

module ECS::Component::StaticMethods
  # Convenience/vanity wrappers for the `new` constructor function.
  def [](*args)
    new(*args)
  end
  def [](**args)
    new(**args)
  end

  # Register this component within the given World.
  def register(world : World)
    desc = LibECS::ComponentDesc.new
    desc.entity.name = ecs_name
    desc.size = sizeof(self)
    desc.alignment = offsetof({self, self}, 1)
    # TODO: desc.entity.add_expr ?

    id = LibECS.component_init(world, pointerof(desc))
    raise Error.new("Failed to register component in the world") \
      if id == 0_u64

    save_id(world, id)
    id
  end
end

module ECS::Component::DSL
  macro _dsl_begin
  end

  macro _dsl_end(name)
    {% ecs_name = name.resolve.id.gsub(/:/, "_") %}
    ECS_NAME = "{{ecs_name}}"

    def self.ecs_name
      ECS_NAME
    end

    class ::ECS::World::Root
      # The id of the {{name}} component is stored here in the World Root.
      property _id_for_{{ecs_name}} = 0_u64
    end

    def self.id(world : World)
      world.root._id_for_{{ecs_name}}
    end

    private def self.save_id(world : World, id : UInt64)
      world.root._id_for_{{ecs_name}} = id
    end
  end
end
