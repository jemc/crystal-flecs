module ECS::DSL::Iter
  # Inject basic methods and mechanisms common to all iterator structs.
  macro inject!(row_type)
    @unsafe : ::ECS::LibECS::Iter*
    @world_root : ::ECS::World::Root
    def initialize(@unsafe, @world_root : ::ECS::World::Root)
    end

    def world
      ::ECS::World.new(@unsafe.value.world, @world_root)
    end

    # Number of entities to process.
    def count : Int32
      @unsafe.value.count
    end

    # Total number of entities in the table.
    def total_count : Int32
      @unsafe.value.total_count
    end

    # Yield each Row to be processed.
    def each
      count = self.count
      index = 0
      while index < count
        yield {{ row_type }}.new(@unsafe, index)
        index = index &+ 1
      end
    end
  end

  # Inject basic methods and mechanisms common to all iterator row structs.
  macro inject_row!
    @unsafe : ::ECS::LibECS::Iter*
    @index : Int32
    def initialize(@unsafe, @index)
    end

    def id
      @unsafe.value.entities[@index]
    end
  end
end
