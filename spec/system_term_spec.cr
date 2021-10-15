require "./spec_helper"

module SystemTermExamples
  ECS.component Age do
    property years : UInt32
    def initialize(@years)
    end
  end

  ECS.system ReadOnly do
    phase "EcsOnStore"

    term x : Age

    def self.run(iter)
    end
  end

  ECS.system ReadWrite do
    phase "EcsOnStore"

    term x : Age, write: true

    def self.run(iter)
    end
  end

  ECS.system WriteOnly do
    phase "EcsOnStore"

    term x : Age, write: true, read: false

    def self.run(iter)
    end
  end

  ECS.system SingletonReadOnly do
    phase "EcsOnStore"

    singleton x : Age

    def self.run(iter)
    end
  end

  ECS.system SingletonReadWrite do
    phase "EcsOnStore"

    singleton x : Age, write: true

    def self.run(iter)
    end
  end

  ECS.system SingletonWriteOnly do
    phase "EcsOnStore"

    singleton x : Age, write: true, read: false

    def self.run(iter)
    end
  end
end

describe System do
  it "can declare a read-only term (by default)" do
    SystemTermExamples::ReadOnly::QUERY_STRING
      .should eq "[in] SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::ReadOnly::Iter)
    iter.should contain "get_x"
    iter.should_not contain "set_x"
    iter.should_not contain "update_x"

    row = method_names_of(SystemTermExamples::ReadOnly::Iter::Row)
    row.should contain "x"
    row.should_not contain "x="
    row.should_not contain "update_x"
  end

  it "can declare a read-write term" do
    SystemTermExamples::ReadWrite::QUERY_STRING
      .should eq "[inout] SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::ReadWrite::Iter)
    iter.should contain "get_x"
    iter.should contain "set_x"
    iter.should contain "update_x"

    row = method_names_of(SystemTermExamples::ReadWrite::Iter::Row)
    row.should contain "x"
    row.should contain "x="
    row.should contain "update_x"
  end

  it "can declare a write-only term" do
    SystemTermExamples::WriteOnly::QUERY_STRING
      .should eq "[out] SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::WriteOnly::Iter)
    iter.should_not contain "get_x"
    iter.should contain "set_x"
    iter.should_not contain "update_x"

    row = method_names_of(SystemTermExamples::WriteOnly::Iter::Row)
    row.should_not contain "x"
    row.should contain "x="
    row.should_not contain "update_x"
  end

  it "can declare a read-only singleton term" do
    SystemTermExamples::SingletonReadOnly::QUERY_STRING
      .should eq "[in] $SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::SingletonReadOnly::Iter)
    iter.should contain "x"
    iter.should_not contain "x="
    iter.should_not contain "update_x"
  end

  it "can declare a read-write singleton term" do
    SystemTermExamples::SingletonReadWrite::QUERY_STRING
      .should eq "[inout] $SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::SingletonReadWrite::Iter)
    iter.should contain "x"
    iter.should contain "x="
    iter.should contain "update_x"
  end

  it "can declare a write-only singleton term" do
    SystemTermExamples::SingletonWriteOnly::QUERY_STRING
      .should eq "[out] $SystemTermExamples__Age"

    iter = method_names_of(SystemTermExamples::SingletonWriteOnly::Iter)
    iter.should_not contain "x"
    iter.should contain "x="
    iter.should_not contain "update_x"
  end
end
