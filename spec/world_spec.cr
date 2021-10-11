require "./spec_helper"

module Example
  struct Age
    property years : UInt64 = 0
    def initialize(@years)
    end
  end

  system PrintAge do
    phase "EcsOnLoad"

    term age : Age

    def run(iter)
      @total_age = 0
      iter.each { |row| @total_age += row.age.years }
      @mean_age = @total_age / iter.count
    end

    property total_age : Int32 = 0
    property mean_age : Float64 = 0
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
    world.get_id(alice, age, Example::Age).years.should eq 99_u64

    world.fini
  end

  it "can run a system" do
    world = World.init

    age = world.component_init(name: "Age", size: 8, alignment: 8)
    alice = world.entity_init(name: "Alice")
    bob = world.entity_init(name: "Bob")
    world.set_id(alice, age, Example::Age.new(99_u64))
    world.set_id(bob, age, Example::Age.new(88_u64))

    system = Example::PrintAge.new
    system.register(world)

    system.total_age.should eq 0
    system.mean_age.should eq 0

    world.progress

    system.total_age.should eq 187
    system.mean_age.should eq 93.5

    world.fini
  end
end
