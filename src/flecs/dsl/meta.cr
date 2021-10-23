require "../lib_ecs"
require "../world"

module ECS::DSL::Meta
  macro entity_for_crystal_type(world, type)
    {% if !type.resolve.struct? || type.stringify.starts_with?("Pointer(") %}
      # For non-struct types, we have a simple, non-macro path for returning them.
      ::ECS::DSL::Meta.entity_prim_for_crystal_type({{ type }})
    {% else %}
      %world = {{ world }}
      struct_name = {{ type.resolve.id.gsub(/:/, "_").stringify }}

      %world.in_scope 0_u64 do
        # If an entity with this name already exists in the world, use it.
        struct_id = %world.lookup(name: struct_name)
        struct_id || begin
          # Otherwise we must declare it as a new entity.
          desc = ::ECS::LibECS::ComponentDesc.new
          desc.entity.name = struct_name
          desc.size = sizeof({{ type }})
          desc.alignment = [sizeof({{ type }}), 8].min
          struct_id = ::ECS::LibECS.component_init(%world, pointerof(desc))

          # And we must declare each of its members, within the scope of it.
          ::ECS::DSL::Meta.register_members({{ world }}, {{ type }}, struct_id)

          struct_id
        end
      end
    {% end %}
  end

  macro register_members(world, type, scope_id)
    %world = {{ world }}

    %world.in_scope {{ scope_id }} do
      {% resolved_type = type.resolve %}
      {% for ivar in resolved_type.instance_vars %}
        # Declare an entity for this struct member.
        member_id = %world.entity_init(name: "{{ivar.name}}")
        %world.set(member_id, ::ECS::Member.new(
          type: ::ECS::DSL::Meta.entity_for_crystal_type(%world, {{ivar.type}}),
          count: 1,
        ))

        # If it has an associated getter method,
        {% if !resolved_type.is_a?(Generic) %}
          {% method = resolved_type.methods.find(&.name.==(ivar.name)) %}
          {% if method && method.return_type.line_number %}
            # Gather documentation lines by crudely loading the source file
            # and gathering up lines beginning with the comment marker, `#`.
            {% lines = read_file(method.filename).lines %}
            {% iter_count = method.return_type.line_number - 1 %}
            {% comment_lines = [] of StringLiteral %}
            {% comment_finished = false %}
            {% for i in (1...iter_count) %}
              {% line = lines[iter_count - i] %}
              {% if !comment_finished && line =~ /\A\s*#/ %}
                {% comment_lines.unshift(line.gsub(/\A\s*#\s*/, "")) %}
              {% else %}
                {% comment_finished = true %}
              {% end %}
            {% end %}

            # If there are any comment lines, register them as docs.
            {% if !comment_lines.empty? %}
              brief = {{ comment_lines.join("\n").split("\n\n")[0].split("\n").join(" ").strip }}
              detail = {{ comment_lines.join("\n") }}
              %world.doc_set_brief(member_id, brief)
              %world.doc_set_detail(member_id, detail)
            {% end %}
          {% end %}
        {% end %}
      {% end %}
    end

    {{ scope_id }}
  end

  def self.entity_prim_for_crystal_type(type) : UInt64
    case type
    when Bool           .class then LibECS.bool_t
    when UInt8          .class then LibECS.u8_t
    when UInt16         .class then LibECS.u16_t
    when UInt32         .class then LibECS.u32_t
    when UInt64         .class then LibECS.u64_t
    when LibC::SizeT    .class then LibECS.uptr_t
    when Int8           .class then LibECS.i8_t
    when Int16          .class then LibECS.i16_t
    when Int32          .class then LibECS.i32_t
    when Int64          .class then LibECS.i64_t
    when Float32        .class then LibECS.f32_t
    when Float64        .class then LibECS.f64_t
    when Pointer(UInt8) .class then LibECS.string_t
    when Reference      .class then LibECS.uptr_t
      # TODO: Error for a Reference, due to GC concerns?
      # Perhaps we should require a DSL arg like `stable: true` to allow it,
      # so that the code author explicitly takes responsibility to prevent GC.
    else
      return LibECS.uptr_t if type.to_s.starts_with?("Pointer(")
      raise NotImplementedError.new("unsupported member type: #{type.inspect}")
    # TODO: Handle embedded structs
    end
  end
end
