require "./spec_helper"

describe World do
  it "can create and destroy a world" do
    world = World.init
    world.fini
  end
end
