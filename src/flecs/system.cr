require "./dsl/system"

module ECS
  macro system(name, &block)
    module {{name}}
      include ::ECS::DSL::System
      _dsl_begin
      {{block.body}}
      _dsl_end
    end
  end
end
