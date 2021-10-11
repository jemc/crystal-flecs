macro system(name, &block)
  class {{name}}
    include ECS::System::DSL

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

    {{block.body}}
  end
end

module ECS::System::DSL
  macro phase(name)
    private def _internal_phase : String; {{name}}; end
  end

  macro query(string, &block)
    private def _internal_query : String; {{string}}; end

    struct Iter
      @unsafe : LibECS::Iter*
      def to_unsafe; @unsafe end
      def initialize(@unsafe)
      end
    end

    def iter
      Iter.new(@iter)
    end
  end

  macro term(decl)
    struct Iter
      def get_{{decl.var}}(index : Int32) : {{decl.type}}
        Pointer(Pointer({{decl.type}})).new(
          self.to_unsafe.value.ptrs.address
        )[0][index]
      end
    end
  end
end
