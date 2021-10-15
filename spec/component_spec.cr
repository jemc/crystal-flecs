require "./spec_helper"

module ComponentExamples
  ECS.component Hooks do
    property dummy : Int32 = 0

    HOOKS_RAN = [] of Symbol
    ID_WHEN_HOOKS_RAN = [] of UInt64

    def self.before_register(world : ECS::World)
      HOOKS_RAN << :before
      ID_WHEN_HOOKS_RAN << id(world)
    end
    def self.after_register(world : ECS::World)
      HOOKS_RAN << :after
      ID_WHEN_HOOKS_RAN << id(world)
    end
  end
end

describe ECS::Component do
  it "can run custom hooks before and after registering with the world" do
    ComponentExamples::Hooks.register(world)

    ComponentExamples::Hooks::HOOKS_RAN.should eq [:before, :after]
    ComponentExamples::Hooks::ID_WHEN_HOOKS_RAN.first.should eq 0
    ComponentExamples::Hooks::ID_WHEN_HOOKS_RAN.last.should_not eq 0
  end
end
