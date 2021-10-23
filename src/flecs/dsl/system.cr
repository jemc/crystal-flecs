require "../lib_ecs"
require "../world"

module ECS::DSL::System
  # Hold some temporary state held in mutable DSL "constants".
  INTERNAL_TERMS_COUNTER = [] of Nil

  macro _dsl_begin
    # Ensure that temporary state in mutable DSL "constants" is clear.
    {%
      raise "Can't declare a system inside a system" \
        unless INTERNAL_TERMS_COUNTER.empty?
    %}

    # The parameter given to a system is an iterator struct, which contains all
    # the context needed to operate on the table/rows/entities in the system.
    #
    # We inject some basic methods here, and will inject further methods later
    # that are specific to the terms present in the system, as conveniently
    # named and strongly typed accessors that can deal with terms.
    struct Iter
      struct Row
        ::ECS::DSL::Iter.inject_row!
      end
      ::ECS::DSL::Iter.inject!(Row)
    end

    # Get ready to accumulate query string fragments as terms are declared.
    QUERY_STRING_TERMS = [] of String

    # Get ready to accumulate other things to be registered.
    ON_REGISTER_HOOKS = [] of ::ECS::World ->
  end

  macro phase(name)
    PHASE = {{name}}
  end

  # Declare a standard term in the query for this system,
  # allowing read or write or read/write access to the given component type
  # under the given accessor name. For every row in the query results,
  # the component will be accessible to read and/or write using the accessors
  # that get implicitly declared by this macro on Iter and Iter::Row.
  macro term(decl, write = false, read = true, of = nil, relate = nil)
    {% name = decl.var %}
    {% type = decl.type %}
    {% subject = of %}
    {% object = relate %}

    struct Iter
      {% if read %}
        def get_{{name}}(index : Int32) : {{type}}
          Pointer(Pointer({{type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][index]
        end
      {% end %}

      {% if write %}
        def set_{{name}}(index : Int32, value : {{type}})
          Pointer(Pointer({{type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][index] = value
        end
      {% end %}

      {% if read && write %}
        def update_{{name}}(index : Int32, &block : {{type}} -> {{type}})
          set_{{name}}(index, yield get_{{name}}(index))
        end
      {% end %}
    end

    struct Iter::Row
      {% if read %}
        def {{name}} : {{type}}
          Pointer(Pointer({{type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][@index]
        end
      {% end %}

      {% if write %}
        def {{name}}=(value : {{type}}) : {{type}}
          Pointer(Pointer({{type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][@index] = value
        end
      {% end %}

      {% if read && write %}
        def update_{{name}}(&block : {{type}} -> {{type}})
          self.{{name}} = yield self.{{name}}
        end
      {% end %}
    end

    {% INTERNAL_TERMS_COUNTER << nil %}

    QUERY_STRING_TERMS << "[#{
      "in" if {{read || !write}}
    }#{
      "out" if {{write}}
    }] #{
      {{type}}::ECS_NAME
    }" +
      {% if subject %}
        {% if object %}
          "(#{{{subject}}::ECS_NAME}, #{{{object}}::ECS_NAME})"
        {% else %}
          "(#{{{subject}}::ECS_NAME})"
        {% end %}
      {% else %}
        {% if object %}
          "(This, #{{{object}}::ECS_NAME})"
        {% else %}
          ""
        {% end %}
      {% end %}


    # Ensure that the component entity is registered before the system entity.
    ON_REGISTER_HOOKS << ->(world : ::ECS::World) { {{decl.type}}.register(world) }
  end

  # Similar to `term`, `singleton` declares a query term,
  # but in this case it refers to a singleton component
  # (i.e. a global entity with the same name as the component itself).
  # As such, this macro only declares accessors on Iter, not Iter::Row.
  macro singleton(decl, write = false, read = true)
    struct Iter
      {% if read %}
        def {{decl.var}} : {{decl.type}}
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}].value
        end
      {% end %}

      {% if write %}
        def {{decl.var}}=(value : {{decl.type}})
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}].value = value
        end
      {% end %}

      {% if read && write %}
        def update_{{decl.var}}(&block : {{decl.type}} -> {{decl.type}})
          self.{{decl.var}} = yield self.{{decl.var}}
        end
      {% end %}
    end

    {% INTERNAL_TERMS_COUNTER << nil %}

    QUERY_STRING_TERMS << "[#{
      "in" if {{read || !write}}
    }#{
      "out" if {{write}}
    }] $#{
      {{ decl.type }}::ECS_NAME
    }"

    # Ensure that the component entity is registered before the system entity.
    ON_REGISTER_HOOKS << ->(world : ::ECS::World) { {{decl.type}}.register(world) }
  end

  macro _dsl_end
    # Define the query string based on the declared terms.
    QUERY_STRING = QUERY_STRING_TERMS.join(", ")

    # Clear temporary state held in mutable DSL "constants".
    {% INTERNAL_TERMS_COUNTER.clear %}

    # Register this system within the given World.
    def self.register(world : ::ECS::World)
      # First register anything the system depends on.
      ON_REGISTER_HOOKS.each(&.call(world))

      desc = ::ECS::LibECS::SystemDesc.new
      desc.entity.name = self.name
      desc.entity.add_expr = PHASE
      desc.query.filter.expr = QUERY_STRING

      desc.ctx = Box.box(world.root)
      desc.callback = ->(iter : ::ECS::LibECS::Iter*) {
        world_root = Box(::ECS::World::Root).unbox(iter.value.ctx)
        run(Iter.new(iter, world_root))
      }

      id = ::ECS::LibECS.system_init(world, pointerof(desc))
    end
  end
end
