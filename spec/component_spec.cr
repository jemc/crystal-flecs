require "./spec_helper"

module ComponentExamples
  ECS.component AfterRegister do
    property dummy : Int32 = 0

    ID_WHEN_HOOK_RAN = [] of UInt64

    def self.after_register(world : ECS::World)
      ID_WHEN_HOOK_RAN << id(world)
    end
  end

  ECS.component ReEntrance do
    property dummy : Int32 = 0

    ID_WHEN_HOOK_RAN = [] of UInt64

    def self.after_register(world : ECS::World)
      register(world)
    end
  end
end

describe ECS::Component do
  it "can run custom hooks before and after registering with the world" do
    id = ComponentExamples::AfterRegister.register(world)

    ComponentExamples::AfterRegister::ID_WHEN_HOOK_RAN.should eq [id]
  end

  it "can call its own register method witout causing an infinite loop" do
    ComponentExamples::ReEntrance.register(world)
  end
end
