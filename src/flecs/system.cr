abstract class ECS::System
  def register(world : World)
    desc = LibECS::SystemDesc.new
    desc.entity.name = self.class.name
    desc.entity.add_expr = self.phase
    desc.query.filter.expr = self.query

    desc.ctx = Box.box(self)
    desc.callback = ->(iter : LibECS::Iter*) {
      system = Box(typeof(self)).unbox(iter.value.ctx)
      system.run
    }

    id = LibECS.system_init(world, pointerof(desc))
  end

  abstract def phase : String
  abstract def query : String

  abstract def run
end
