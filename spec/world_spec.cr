require "./spec_helper"

module WorldExamples
  ECS.component Age do
    property years : UInt64 = 0
    def initialize(@years)
    end
  end
end

describe ECS::World do
  it "can create an entity and retrieve the same entity by name" do
    foo = world.entity_init(name: "Foo")

    world.lookup(name: "Foo").should eq foo
    world.lookup(name: "Bar").should eq nil

    world.entity_init(name: "Foo").should eq foo
    world.entity_init(name: "Bar").should_not eq foo
  end

  it "can set, get, and remove the value of a component on an entity" do
    WorldExamples::Age.register(world)

    alice = world.entity_init(name: "Alice")

    world.get(alice, WorldExamples::Age).should eq nil
    world.set(alice, WorldExamples::Age[99_u64])
    world.get(alice, WorldExamples::Age).not_nil!.years.should eq 99_u64
    world.remove(alice, WorldExamples::Age)
    world.get(alice, WorldExamples::Age).should eq nil
  end

  it "can set, get, and remove the value of a singleton component" do
    WorldExamples::Age.register(world)

    world.get_singleton(WorldExamples::Age).should eq nil
    world.set_singleton(WorldExamples::Age[99_u64])
    world.get_singleton(WorldExamples::Age).not_nil!.years.should eq 99_u64
    world.remove_singleton(WorldExamples::Age)
    world.get_singleton(WorldExamples::Age).should eq nil
  end

  it "can set, get, and remove the value of a relation component" do
    WorldExamples::Age.register(world)

    alice = world.entity_init(name: "Alice")
    house = world.entity_init(name: "House")

    world.get_relation(alice, WorldExamples::Age, house).should eq nil
    world.set_relation(alice, WorldExamples::Age[10_u64], house)
    world.get_relation(alice, WorldExamples::Age, house).not_nil!.years.should eq 10_u64
    world.remove_relation(alice, WorldExamples::Age, house)
    world.get_relation(alice, WorldExamples::Age, house).should eq nil
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
