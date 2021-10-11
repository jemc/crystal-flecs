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
      def to_unsafe; @unsafe end
      def initialize(@unsafe)
      end
    end

    def register(world : World)
      desc = LibECS::SystemDesc.new
      desc.entity.name = self.class.name
      desc.entity.add_expr = self._internal_phase
      desc.query.filter.expr = self._internal_query

      desc.ctx = Box.box(self)
      desc.callback = ->(iter : LibECS::Iter*) {
        system = Box(typeof(self)).unbox(iter.value.ctx)
        system.run(Iter.new(iter))
      }

      id = LibECS.system_init(world, pointerof(desc))
    end
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

    def _internal_query: String; QUERY_STRING; end # TODO: Remove this

    # Clear temporary state held in mutable DSL "constants".
    {% INTERNAL_CURRENT_TERM_DECLS.clear %}
  end

  macro phase(name)
    private def _internal_phase : String; {{name}}; end
  end

  macro term(decl)
    struct Iter
      def get_{{decl.var}}(index : Int32) : {{decl.type}}
        Pointer(Pointer({{decl.type}})).new(
          self.to_unsafe.value.ptrs.address
        )[{{ INTERNAL_CURRENT_TERM_DECLS.size }}][index]
      end
    end

    {% INTERNAL_CURRENT_TERM_DECLS << decl %}
  end
end
