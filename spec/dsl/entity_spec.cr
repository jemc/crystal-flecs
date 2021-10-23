require "../spec_helper"

module EntityExamples
  ECS.component Age do
    property years : UInt32
    def initialize(@years)
    end
  end

  ECS.component ApprenticeOf do
    property skill : String
    def initialize(@skill)
    end
  end

  ECS.entity Alice

  ECS.entity Bob do
    set Age[99_u32]
    set ApprenticeOf["carpentry"], Alice
  end
end

describe ECS::DSL::Entity do
  it "can be registered to obtain an id" do
    EntityExamples::Alice.id(world).should eq 0

    id = EntityExamples::Alice.register(world)
    id.should_not eq 0

    EntityExamples::Alice.id(world).should eq id

    # Registering redundantly gives the same id.
    EntityExamples::Alice.register(world).should eq id
    EntityExamples::Alice.id(world).should eq id
  end

  it "can set components declaratively to be retrieved later" do
    EntityExamples::Bob.register(world)

    world.get(EntityExamples::Bob, EntityExamples::Age)
      .not_nil!.years.should eq 99_u32

    world.get_relation(EntityExamples::Bob,
      EntityExamples::ApprenticeOf, EntityExamples::Alice)
      .not_nil!.skill.should eq "carpentry"
  end
end
