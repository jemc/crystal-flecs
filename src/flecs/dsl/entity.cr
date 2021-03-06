require "../lib_ecs"
require "../world"

module ECS::DSL::Entity
  macro _dsl_begin
    # Get ready to accumulate other things to do after registering.
    AFTER_REGISTER_HOOKS = [] of (::ECS::World, UInt64) ->
  end

  macro set(component, object = nil)
    {% if object %}
      AFTER_REGISTER_HOOKS << ->(world : ::ECS::World, id : UInt64) {
        component = {{component}}
        object = {{object}}

        component.class.register(world)
        object.register(world) if object.responds_to?(:register)

        world.set_relation(id, component, object)
      }
    {% else %}
      AFTER_REGISTER_HOOKS << ->(world : ::ECS::World, id : UInt64) {
        component = {{component}}

        component.class.register(world)

        world.set(id, component)
      }
    {% end %}
  end

  macro _dsl_end(name, is_extern)
    {% ecs_name = name.resolve.id.gsub(/:/, "_") %}

    {% if !is_extern %}
      ECS_NAME = "{{ecs_name}}"
    {% end %}

    def self.ecs_name
      ECS_NAME
    end

    def self.is_extern?
      {{is_extern}}
    end

    class ::ECS::World::Root
      # The id of the {{name}} entity is stored here in the World Root.
      property _id_for_{{ecs_name}} = 0_u64
    end

    def self.id(world : ::ECS::World)
      world.root._id_for_{{ecs_name}}
    end

    private def self.save_id(world : ::ECS::World, id : UInt64)
      world.root._id_for_{{ecs_name}} = id
    end

    # Register this entity within the given World.
    def self.register(world : ::ECS::World)
      if is_extern?
        return save_id(world, world.lookup_fullpath(ecs_name).not_nil!)
      end

      the_self = self
      # If the entity author declared a before_register method, run it now.
      if the_self.responds_to?(:before_register)
        the_self.before_register(world)
      end

      # Prepare the entity descriptor.
      desc = ::ECS::LibECS::EntityDesc.new
      desc.name = self.ecs_name
      # TODO: desc.add_expr ?

      # Register the entity and save its id in the world root.
      id = ::ECS::LibECS.entity_init(world, pointerof(desc))
      raise ::ECS::Error.new("Failed to register entity in the world") if id == 0_u64
      save_id(world, id)

      # Now run the internal after register hooks.
      AFTER_REGISTER_HOOKS.each(&.call(world, id))

      # If the entity author declared an after_register method, run it now.
      if the_self.responds_to?(:after_register)
        the_self.after_register(world)
      end

      id
    end
  end
end
