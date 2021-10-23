require "./dsl/component"

module ECS
  macro component(name, &block)
    struct {{name}}
      extend ::ECS::DSL::Component::StaticMethods
      include ::ECS::DSL::Component
      _dsl_begin
      {{block.body}}
      _dsl_end({{name}}, false)
    end
  end

  macro builtin_component(name, &block)
    struct {{name}}
      extend ::ECS::DSL::Component::StaticMethods
      include ::ECS::DSL::Component
      _dsl_begin
      {{block.body}}
      _dsl_end({{name}}, true)
    end
  end
end
