require "./spec_helper"

describe World do
  it "can create an entity and retrieve the same entity by name" do
    world = World.init

    foo = world.entity_init(name: "Foo")
    world.entity_init(name: "Foo").should eq foo
    world.entity_init(name: "Bar").should_not eq foo

    world.fini
  end
end
