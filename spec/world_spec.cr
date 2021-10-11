require "./spec_helper"

module WorldSpec
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
    WorldSpec::Age.register(world)

    alice = world.entity_init(name: "Alice")

    world.set(alice, WorldSpec::Age.new(99_u64))
    world.get(alice, WorldSpec::Age).years.should eq 99_u64
  end
end
