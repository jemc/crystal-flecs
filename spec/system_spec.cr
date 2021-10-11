require "./spec_helper"

module SystemExamples
  component Age do
    property years : UInt32 = 0
    property other_years : UInt32 = 0
    def initialize(@years)
    end
  end

  system IncrementAge do
    phase "EcsOnUpdate"

    term age : Age, write: true

    def run(iter)
      iter.each { |row|
        row.update_age { |age|
          age.years &+= 1
          age.other_years &+= 1
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
      iter.each { |row| @total_age &+= row.age.years }
      @mean_age = @total_age / iter.count
    end

    property total_age : Int32 = 0
    property mean_age : Float64 = 0
  end
end

describe System do
  it "can be declared and ran" do
    SystemExamples::IncrementAge::QUERY_STRING
      .should eq "[inout] SystemExamples__Age"
    SystemExamples::PrintAge::QUERY_STRING
      .should eq "[in] SystemExamples__Age"

    SystemExamples::IncrementAge.new.register(world)
    system = SystemExamples::PrintAge.new
    system.register(world)

    alice = world.entity_init(name: "Alice")
    bob = world.entity_init(name: "Bob")

    world.set(alice, SystemExamples::Age.new(99_u32))
    world.set(bob, SystemExamples::Age.new(88_u32))

    system.total_age.should eq 0
    system.mean_age.should eq 0

    world.progress

    system.total_age.should eq 189
    system.mean_age.should eq 94.5

    world.progress

    system.total_age.should eq 191
    system.mean_age.should eq 95.5
  end
end
