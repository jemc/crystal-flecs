module ECS
  macro system(name, &block)
    module {{name}}
      include ECS::System::DSL
      _dsl_begin
      {{block.body}}
      _dsl_end
    end
  end
end

module ECS::System::DSL
  # Hold some temporary state held in mutable DSL "constants".
  INTERNAL_TERMS_COUNTER = [] of Nil

  macro _dsl_begin
    # Ensure that temporary state in mutable DSL "constants" is clear.
    {%
      raise "Can't declare a system inside a system" \
        unless INTERNAL_TERMS_COUNTER.empty?
    %}

    struct Iter
      @unsafe : ::ECS::LibECS::Iter*
      @world_root : ::ECS::World::Root
      def initialize(@unsafe, @world_root : ::ECS::World::Root)
      end

      # A table row to be processed by the system during iteration.
      #
      # It contains macro-generated accessor methods for each term
      # named during declaration of the system (via the DSL).
      struct Row
        @unsafe : ::ECS::LibECS::Iter*
        @index : Int32
        def initialize(@unsafe, @index)
        end
      end

      def world
        ::ECS::World.new(@unsafe.value.world, @world_root)
      end

      # Number of entities to process by system.
      def count : Int32
        @unsafe.value.count
      end

      # Total number of entities in table.
      def total_count : Int32
        @unsafe.value.total_count
      end

      # Yield each Row to be processed by the system.
      def each
        count = self.count
        index = 0
        while index < count
          yield Row.new(@unsafe, index)
          index = index &+ 1
        end
      end
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
  macro term(decl, write = false, read = true)
    struct Iter
      {% if read %}
        def get_{{decl.var}}(index : Int32) : {{decl.type}}
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][index]
        end
      {% end %}

      {% if write %}
        def set_{{decl.var}}(index : Int32, value : {{decl.type}})
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][index] = value
        end
      {% end %}

      {% if read && write %}
        def update_{{decl.var}}(index : Int32, &block : {{decl.type}} -> {{decl.type}})
          set_{{decl.var}}(index, yield get_{{decl.var}}(index))
        end
      {% end %}
    end

    struct Iter::Row
      {% if read %}
        def {{decl.var}} : {{decl.type}}
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][@index]
        end
      {% end %}

      {% if write %}
        def {{decl.var}}=(value : {{decl.type}}) : {{decl.type}}
          Pointer(Pointer({{decl.type}})).new(
            @unsafe.value.ptrs.address
          )[{{ INTERNAL_TERMS_COUNTER.size }}][@index] = value
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
      "in" if {{read}}
    }#{
      "out" if {{write}}
    }] #{
      {{ decl.type }}::ECS_NAME
    }"

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
      "in" if {{read}}
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
