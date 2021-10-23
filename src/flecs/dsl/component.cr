require "../lib_ecs"
require "../world"
require "./meta"
require "./trigger"

module ECS::DSL::Component::StaticMethods
  # Convenience/vanity wrappers for the `new` constructor function.
  def [](*args)
    new(*args)
  end
  def [](**args)
    new(**args)
  end

  # Register this component within the given World.
  def register(world : ::ECS::World)
    # If the id is already registered, don't continue.
    return if id(world) != 0

    if is_extern?
      return save_id(world, world.lookup_fullpath(ecs_name).not_nil!)
    end

    desc = ::ECS::LibECS::ComponentDesc.new
    desc.entity.name = ecs_name
    desc.size = sizeof(self)
    desc.alignment = [sizeof(self), 8].min
    # TODO: desc.entity.add_expr ?

    id = ::ECS::LibECS.component_init(world, pointerof(desc))
    raise Error.new("Failed to register component in the world") \
      if id == 0_u64

    save_id(world, id)

    ::ECS::DSL::Meta.register_members(world, {{@type}}, id) unless is_extern?

    # Register standard on_add/on_remove triggers, if defined.
    {% if @type.class.methods.find(&.name.==("on_add")) %}
      ::ECS::DSL::Trigger.register_basic_on_add(world, {{ @type }}, id)
    {% end %}
    {% if @type.class.methods.find(&.name.==("on_remove")) %}
      ::ECS::DSL::Trigger.register_basic_on_remove(world, {{ @type }}, id)
    {% end %}

    # If the component author declared an after_register method, run it now.
    the_self = self
    if the_self.responds_to?(:after_register)
      the_self.after_register(world)
    end

    id
  end
end

module ::ECS::DSL::Component
  macro _dsl_begin
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
      # The id of the {{name}} component is stored here in the World Root.
      property _id_for_{{ecs_name}} = 0_u64
    end

    def self.id(world : ::ECS::World)
      world.root._id_for_{{ecs_name}}
    end

    private def self.save_id(world : ::ECS::World, id : UInt64)
      world.root._id_for_{{ecs_name}} = id
    end

    # For each setter method, define a convenience mutator that wraps it.
    {% for setter in @type.methods %}
      {% if setter.name.ends_with?("=") %}
        {% property_name = setter.name.stringify.gsub(/=\z/, "").id %}

        # Update the {{ property_name }} and return self for chaining.
        #
        # This is useful for mutating a struct because it ensures that the
        # mutated instance of the struct is what is returned.
        def with_{{ property_name }}(value)
          self.{{ setter.name }} value
          self
        end
      {% end %}
    {% end %}
  end
end
