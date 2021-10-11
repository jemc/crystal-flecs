macro component(name, &block)
  struct {{name}}
    include ECS::Component::DSL
    _dsl_begin
    {{block.body}}
    _dsl_end({{name}})
  end
end

module ECS::Component::DSL
  macro _dsl_begin
  end

  macro _dsl_end(name)
    {% ecs_name = name.resolve.id.gsub(/:/, "_") %}
    ECS_NAME = "{{ecs_name}}"

    class ::ECS::World::Root
      # The id of the {{name}} component is stored here in the World Root.
      property _id_for_{{ecs_name}} = 0_u64
    end

    def self.id(world : World)
      world.root._id_for_{{ecs_name}}
    end

    # Register this component within the given World.
    def self.register(world : World)
      desc = LibECS::ComponentDesc.new
      desc.entity.name = ECS_NAME
      desc.size = sizeof(self)
      desc.alignment = offsetof({self, self}, 1)
      # TODO: desc.entity.add_expr ?

      world.root._id_for_{{ecs_name}} = id =
        LibECS.component_init(world, pointerof(desc))

      if id == 0_u64
        raise Error.new("Failed to register component in the world")
      end

      id
    end
  end
end
