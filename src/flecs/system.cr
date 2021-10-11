macro system(name, &block)
  class {{name}}
    include ECS::System::DSL
    _dsl_begin
    {{block.body}}
    _dsl_end
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
      @unsafe : LibECS::Iter*
      def initialize(@unsafe)
      end

      # A table row to be processed by the system during iteration.
      #
      # It contains macro-generated accessor methods for each term
      # named during declaration of the system (via the DSL).
      struct Row
        @unsafe : LibECS::Iter*
        @index : Int32
        def initialize(@unsafe, @index)
        end
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
  end

  macro phase(name)
    PHASE = {{name}}
  end

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
  end

  macro _dsl_end
    # Define the query string based on the declared terms.
    QUERY_STRING = QUERY_STRING_TERMS.join(", ")

    # Clear temporary state held in mutable DSL "constants".
    {% INTERNAL_TERMS_COUNTER.clear %}

    # Register this system within the given World.
    def register(world : World)
      desc = LibECS::SystemDesc.new
      desc.entity.name = self.class.name
      desc.entity.add_expr = PHASE
      desc.query.filter.expr = QUERY_STRING

      desc.ctx = Box.box(self)
      desc.callback = ->(iter : LibECS::Iter*) {
        system = Box(typeof(self)).unbox(iter.value.ctx)
        system.run(Iter.new(iter))
      }

      id = LibECS.system_init(world, pointerof(desc))
    end
  end
end
