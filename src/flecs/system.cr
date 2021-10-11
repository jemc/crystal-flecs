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
  INTERNAL_CURRENT_TERM_DECLS = [] of _

  macro _dsl_begin
    # Ensure that temporary state in mutable DSL "constants" is clear.
    {%
      raise "Can't declare a system inside a system" \
        unless INTERNAL_CURRENT_TERM_DECLS.empty?
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
          index += 1
        end
      end
    end
  end

  macro phase(name)
    PHASE = {{name}}
  end

  macro term(decl)
    struct Iter
      def get_{{decl.var}}(index : Int32) : {{decl.type}}
        Pointer(Pointer({{decl.type}})).new(
          @unsafe.value.ptrs.address
        )[{{ INTERNAL_CURRENT_TERM_DECLS.size }}][index]
      end
    end

    struct Iter::Row
      def {{decl.var}} : {{decl.type}}
        Pointer(Pointer({{decl.type}})).new(
          @unsafe.value.ptrs.address
        )[{{ INTERNAL_CURRENT_TERM_DECLS.size }}][@index]
      end
    end

    {% INTERNAL_CURRENT_TERM_DECLS << decl %}
  end

  macro _dsl_end
    # Define the query string based on the declared terms.
    QUERY_STRING =
      {% begin %}
        [
          {% for term_decl in INTERNAL_CURRENT_TERM_DECLS %}
            "#{{{ term_decl.type }}}".split("::").last
          {% end %}
        ].join(", ")
      {% end %}

    # Clear temporary state held in mutable DSL "constants".
    {% INTERNAL_CURRENT_TERM_DECLS.clear %}

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
