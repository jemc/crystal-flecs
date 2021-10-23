require "../lib_ecs"
require "../world"

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

    if is_builtin?
      return save_id(world, world.lookup_fullpath(ecs_name).not_nil!)
    end

    desc = ::ECS::LibECS::ComponentDesc.new
    desc.entity.name = ecs_name
    desc.size = sizeof(self)
    desc.alignment = offsetof({self, self}, 1)
    # TODO: desc.entity.add_expr ?

    id = ::ECS::LibECS.component_init(world, pointerof(desc))
    raise Error.new("Failed to register component in the world") \
      if id == 0_u64

    save_id(world, id)

    register_docs(world, id) unless is_builtin?

    # If the component author declared an after_register method, run it now.
    the_self = self
    if the_self.responds_to?(:after_register)
      the_self.after_register(world)
    end

    id
  end

  def register_docs(world : ::ECS::World, id : UInt64)
    # Start declaring entities within the scope of this entity.
    world.in_scope id do
      # For every instance variable in the type,
      {% for ivar in @type.instance_vars %}
        # If it has an associated getter method,
        {% method = @type.methods.find(&.name.==(ivar.name)) %}
        {% if method %}
          # Gather documentation lines by crudely loading the source file
          # and gathering up lines beginning with the comment marker, `#`.
          {% lines = read_file(method.filename).lines %}
          {% iter_count = method.return_type.line_number - 1 %}
          {% comment_lines = [] of StringLiteral %}
          {% comment_finished = false %}
          {% for i in (1...iter_count) %}
            {% line = lines[iter_count - i] %}
            {% if !comment_finished && line =~ /\A\s*#/ %}
              {% comment_lines.unshift(line.gsub(/\A\s*#\s*/, "")) %}
            {% else %}
              {% comment_finished = true %}
            {% end %}
          {% end %}

          # If there are any comment lines, register them as docs.
          {% if !comment_lines.empty? %}
            name = "{{ivar.name}}"
            brief = {{ comment_lines.join("\n").split("\n\n")[0].split("\n").join(" ").strip }}
            detail = {{ comment_lines.join("\n") }}

            member_id = world.entity_init(name: name)
            world.set(member_id, ::ECS::Member.new(
              type: world.ecs_type_from_crystal_member_type({{ivar.type}}),
              count: 1,
            ))

            world.doc_set_brief(member_id, brief)
            world.doc_set_detail(member_id, detail)
          {% end %}
        {% end %}
      {% end %}
    end
  end
end

module ::ECS::DSL::Component
  macro _dsl_begin
  end

  macro _dsl_end(name, is_builtin)
    {% ecs_name = name.resolve.id.gsub(/:/, "_") %}

    {% if !is_builtin %}
      ECS_NAME = "{{ecs_name}}"
    {% end %}

    def self.ecs_name
      ECS_NAME
    end

    def self.is_builtin?
      {{is_builtin}}
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
  end
end
