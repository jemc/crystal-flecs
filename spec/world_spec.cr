require "./spec_helper"

module WorldExamples
  component Age do
    property years : UInt64 = 0
    def initialize(@years)
    end
  end
end

describe World do
  it "can create an entity and retrieve the same entity by name" do
    foo = world.entity_init(name: "Foo")
    world.entity_init(name: "Foo").should eq foo
    world.entity_init(name: "Bar").should_not eq foo
  end

  it "can set and get the value of a component on an entity" do
    WorldExamples::Age.register(world)

    alice = world.entity_init(name: "Alice")

    world.set(alice, WorldExamples::Age[99_u64])
    world.get(alice, WorldExamples::Age).years.should eq 99_u64
  end

  it "can tell the total number of frames that have elapsed" do
    world.info.frame_count_total.should eq 0
    world.progress
    world.info.frame_count_total.should eq 1
    world.progress
    world.info.frame_count_total.should eq 2
  end

  it "can get and set the target FPS value" do
    world.target_fps.should eq 0
    world.info.target_fps.should eq 0

    world.target_fps = 60
    world.target_fps.should eq 60
    world.info.target_fps.should eq 60

    world.target_fps = 30
    world.target_fps.should eq 30
    world.info.target_fps.should eq 30
  end
end
