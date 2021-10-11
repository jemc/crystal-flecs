require "./spec_helper"

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
end
