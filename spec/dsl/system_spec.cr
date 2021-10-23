require "../spec_helper"

module SystemExamples
  ECS.component Age do
    property years : UInt32
    def initialize(@years)
    end
  end

  ECS.component AgeStats do
    property mean : Float64
    property total : UInt32
    property id_total : UInt64
    def initialize(@mean = 0_f64, @total = 0_u32, @id_total = 0_u64)
    end
  end

  ECS.system IncrementAge do
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

  ECS.system SurveyAge do
    phase "EcsOnStore"

    term age : Age
    singleton stats : AgeStats, write: true, read: false

    def self.run(iter)
      age_total = 0_u32
      id_total = 0_u64

      iter.each { |row|
        age_total &+= row.age.years
        id_total &+= row.id
      }
      age_mean = age_total / iter.count

      iter.stats = AgeStats[
        mean: age_mean,
        total: age_total,
        id_total: id_total,
      ]
    end
  end
end

describe ECS::DSL::System do
  it "can be declared and ran" do
    SystemExamples::IncrementAge::QUERY_STRING
      .should eq "[inout] SystemExamples__Age"
    SystemExamples::SurveyAge::QUERY_STRING
      .should eq "[in] SystemExamples__Age, [out] $SystemExamples__AgeStats"

    SystemExamples::IncrementAge.register(world)
    SystemExamples::SurveyAge.register(world)

    alice = world.entity_init(name: "Alice")
    bob = world.entity_init(name: "Bob")

    world.set(alice, SystemExamples::Age[99_u32])
    world.set(bob, SystemExamples::Age[88_u32])

    stats = world.set_singleton(SystemExamples::AgeStats[]).not_nil!
    stats.mean.should eq 0
    stats.total.should eq 0
    stats.id_total.should eq 0

    world.progress

    stats = world.get_singleton(SystemExamples::AgeStats).not_nil!
    stats.mean.should eq 94.5
    stats.total.should eq 189
    stats.id_total.should eq alice + bob

    world.progress

    stats = world.get_singleton(SystemExamples::AgeStats).not_nil!
    stats.mean.should eq 95.5
    stats.total.should eq 191
    stats.id_total.should eq alice + bob
  end
end
