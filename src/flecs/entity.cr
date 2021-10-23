require "./dsl/entity"

module ECS
  macro entity(name, &block)
    module {{name}}
      include ::ECS::DSL::Entity
      _dsl_begin
      {{block.body if block}}
      _dsl_end({{name}})
    end
  end
end
