require "../spec_helper"

module ComponentExamples
  ECS.component AfterRegister do
    property dummy : Int32 = 0

    ID_WHEN_HOOK_RAN = [] of UInt64

    def self.after_register(world : ECS::World)
      ID_WHEN_HOOK_RAN << id(world)
    end
  end

  ECS.component ReEntrance do
    property dummy : Int32 = 0

    def self.after_register(world : ECS::World)
      register(world)
    end
  end

  ECS.component Documented do
    # This is the foo.
    #
    # It is a number that indicates the foo.
    property foo : Int32 = 0

    # This is the bar.
    #
    # Please always get it from a string literal!
    property bar : Pointer(UInt8) = "foo".to_unsafe
  end
end

describe ECS::DSL::Component do
  it "can run custom hooks before and after registering with the world" do
    id = ComponentExamples::AfterRegister.register(world)

    ComponentExamples::AfterRegister::ID_WHEN_HOOK_RAN.should eq [id]
  end

  it "can call its own register method witout causing an infinite loop" do
    ComponentExamples::ReEntrance.register(world)
  end

  it "registers documentation and meta information" do
    ComponentExamples::Documented.register(world)

    c_name = ComponentExamples::Documented.ecs_name
    foo_id = world.lookup_fullpath("#{c_name}.foo").not_nil!
    bar_id = world.lookup_fullpath("#{c_name}.bar").not_nil!

    foo_type = world.get(foo_id, ECS::Member).not_nil!.type
    bar_type = world.get(bar_id, ECS::Member).not_nil!.type

    foo_type.should eq ECS::LibECS.i32_t
    bar_type.should eq ECS::LibECS.string_t

    world.doc_get_brief(foo_id).not_nil!.should eq \
      "This is the foo."
    world.doc_get_detail(foo_id).not_nil!.should eq \
      "This is the foo.\n\nIt is a number that indicates the foo."

    world.doc_get_brief(bar_id).not_nil!.should eq \
      "This is the bar."
    world.doc_get_detail(bar_id).not_nil!.should eq \
      "This is the bar.\n\nPlease always get it from a string literal!"
  end
end
