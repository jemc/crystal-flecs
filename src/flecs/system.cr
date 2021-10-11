abstract class ECS::System
  @iter = Pointer(LibECS::Iter).null
  protected def set_current_iter(iter : LibECS::Iter*)
    @iter = iter
  end

  abstract def run

  macro phase(name)
    private def _internal_phase : String; {{name}}; end
  end
  private abstract def _internal_phase : String

  macro query(string)
    private def _internal_query : String; {{string}}; end
  end
  private abstract def _internal_query : String

  macro term(decl)
    private def get_{{decl.var}}(index : Int32) : {{decl.type}}
      Pointer(Pointer({{decl.type}})).new(
        @iter.value.ptrs.address
      )[0][index]
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
      system.set_current_iter(iter)
      system.run
    }

    id = LibECS.system_init(world, pointerof(desc))
  end
end
