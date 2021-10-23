require "../lib_ecs"
require "../world"
require "./iter"

module ECS::DSL::Trigger
  macro register_basic_on_add(world, type, id)
    %world = {{ world }}

    %desc = ::ECS::LibECS::TriggerDesc.new
    %desc.entity.name = "#{{{ type }}::ECS_NAME}__on_add"
    %desc.term.pred.entity = id
    %desc.events[0] = ::ECS::OnAdd.id(world)
    %desc.match_prefab = true # TODO: configurable?
    %desc.match_disabled = true # TODO: configurable?

    %desc.ctx = Box.box(world.root)
    %desc.callback = ->(iter : ::ECS::LibECS::Iter*) {
      world_root = Box(::ECS::World::Root).unbox(iter.value.ctx)
      on_add(::ECS::DSL::Trigger::IterOnAdd({{ type }}).new(iter, world_root))
      nil
    }

    ::ECS::LibECS.trigger_init(world, pointerof(%desc))
  end

  macro register_basic_on_remove(world, type, id)
    %world = {{ world }}

    %desc = ::ECS::LibECS::TriggerDesc.new
    %desc.entity.name = "#{{{ type }}::ECS_NAME}__on_remove"
    %desc.term.pred.entity = id
    %desc.events[0] = ::ECS::OnRemove.id(world)
    %desc.match_prefab = true # TODO: configurable?
    %desc.match_disabled = true # TODO: configurable?

    %desc.ctx = Box.box(world.root)
    %desc.callback = ->(iter : ::ECS::LibECS::Iter*) {
      world_root = Box(::ECS::World::Root).unbox(iter.value.ctx)
      on_remove(::ECS::DSL::Trigger::IterOnRemove({{ type }}).new(iter, world_root))
      nil
    }

    ::ECS::LibECS.trigger_init(world, pointerof(%desc))
  end

  struct IterOnAdd(T)
    struct Row(T)
      ::ECS::DSL::Iter.inject_row!
    end
    ::ECS::DSL::Iter.inject!(Row(T))
  end

  struct IterOnRemove(T)
    struct Row(T)
      ::ECS::DSL::Iter.inject_row!

      # The component value for this row.
      def value
        Pointer(Pointer(T)).new(@unsafe.value.ptrs.address)[0][@index]
      end
    end
    ::ECS::DSL::Iter.inject!(Row(T))
  end
end
