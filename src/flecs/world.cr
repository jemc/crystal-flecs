struct ECS::World
  @unsafe : LibECS::WorldRef
  def to_unsafe; @unsafe end
  def initialize(@unsafe)
  end

  # Create a new world.
  #
  # A world manages all the ECS data and supporting infrastructure. Applications
  # must have at least one world. Entities, component and system handles are
  # local to a world and should not be shared between worlds.
  #
  # This operation creates a world with all builtin modules loaded.
  def self.init
    new(LibECS.init)
  end

  # Delete a world.
  #
  # This operation deletes the world, and everything it contains.
  def fini
    raise Error.new("Failed to destroy the given world") \
      unless 0 == LibECS.fini(self)
  end
end
