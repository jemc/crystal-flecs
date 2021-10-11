require "./spec_helper"

module SystemExamples
  component Age do
    property years : UInt32
    def initialize(@years)
    end
  end

  component AgeStats do
    property mean : Float64
    property total : UInt32
    def initialize(@mean = 0_f64, @total = 0_u32)
    end
  end

  system IncrementAge do
    phase "EcsOnUpdate"

    term age : Age, write: true

    def self.run(iter)
      iter.each { |row|
        row.update_age { |age|
          age.years &+= 1
          age
        }
      }
    end
  end

  system SurveyAge do
    phase "EcsOnStore"

    term age : Age
    singleton stats : AgeStats, write: true, read: false

    def self.run(iter)
      total_age = 0_u32
      iter.each { |row| total_age &+= row.age.years }
      mean_age = total_age / iter.count

      iter.stats = AgeStats.new(mean: mean_age, total: total_age)
    end
  end
end

describe System do
  it "can be declared and ran" do
    SystemExamples::IncrementAge::QUERY_STRING
      .should eq "[inout] SystemExamples__Age"
    SystemExamples::SurveyAge::QUERY_STRING
      .should eq "[in] SystemExamples__Age, [out] $SystemExamples__AgeStats"

    SystemExamples::IncrementAge.register(world)
    SystemExamples::SurveyAge.register(world)

    alice = world.entity_init(name: "Alice")
    bob = world.entity_init(name: "Bob")

    world.set(alice, SystemExamples::Age.new(99_u32))
    world.set(bob, SystemExamples::Age.new(88_u32))

    stats = world.set_singleton(SystemExamples::AgeStats.new)
    stats.mean.should eq 0
    stats.total.should eq 0

    world.progress

    stats = world.get_singleton(SystemExamples::AgeStats)
    stats.mean.should eq 94.5
    stats.total.should eq 189

    world.progress

    stats = world.get_singleton(SystemExamples::AgeStats)
    stats.mean.should eq 95.5
    stats.total.should eq 191
  end
end
