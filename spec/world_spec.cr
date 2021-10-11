require "./spec_helper"

module Example
  component Age do
    property years : UInt64 = 0
    def initialize(@years)
    end
  end

  system IncrementAge do
    phase "EcsOnUpdate"

    term age : Age, write: true

    def run(iter)
      iter.each { |row|
        row.update_age { |age|
          age.years += 1
          age
        }
      }
    end
  end

  system PrintAge do
    phase "EcsOnStore"

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

  it "can set and get the value of a component on an entity" do
    world = World.init
    Example::Age.register(world)

    alice = world.entity_init(name: "Alice")

    world.set(alice, Example::Age.new(99_u64))
    world.get(alice, Example::Age).years.should eq 99_u64

    world.fini
  end

  it "can run a system" do
    world = World.init

    Example::Age.register(world)
    alice = world.entity_init(name: "Alice")
    bob = world.entity_init(name: "Bob")

    world.set(alice, Example::Age.new(99_u64))
    world.set(bob, Example::Age.new(88_u64))

    Example::IncrementAge::QUERY_STRING.should eq "[inout] Example__Age"
    Example::PrintAge::QUERY_STRING.should eq "[in] Example__Age"

    Example::IncrementAge.new.register(world)
    system = Example::PrintAge.new
    system.register(world)

    system.total_age.should eq 0
    system.mean_age.should eq 0

    world.progress

    system.total_age.should eq 189
    system.mean_age.should eq 94.5

    world.progress

    system.total_age.should eq 191
    system.mean_age.should eq 95.5

    world.fini
  end
end
