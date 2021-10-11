require "./spec_helper"

module Example
  struct Age
    property age : UInt64 = 0
    def initialize(@age)
    end
  end
end

describe World do
  it "can create an entity and retrieve the same entity by name" do
    world = World.init

    foo = world.entity_init(name: "Foo")
    world.entity_init(name: "Foo").should eq foo
    world.entity_init(name: "Bar").should_not eq foo

    world.fini
  end

  it "can create a component and retrieve the same component by name" do
    world = World.init

    foo = world.component_init(name: "Foo", size: 8, alignment: 8)
    world.component_init(name: "Foo", size: 8, alignment: 8).should eq foo
    world.component_init(name: "Bar", size: 8, alignment: 8).should_not eq foo

    world.fini
  end

  it "can set and get the value of a component on an entity" do
    world = World.init

    age = world.component_init(name: "Age", size: 8, alignment: 8)
    alice = world.entity_init(name: "Alice")

    world.set_id(alice, age, Example::Age.new(99_u64))
    world.get_id(alice, age, Example::Age).age.should eq 99_u64

    world.fini
  end
end
