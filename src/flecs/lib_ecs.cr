module ECS
  @[Link(ldflags: "-L#{__DIR__}/../../vendor -lflecs")]
  lib LibECS
    type WorldRef = Void*
    type QueryRef = Void*
    type TableRef = Void*
    type TypeRef = Void*
    type EntityRefRef = Void*

    struct WorldInfo
      last_component_id : UInt64
      last_id : UInt64
      min_id : UInt64
      max_id : UInt64
      delta_time_raw : Float32
      delta_time : Float32
      time_scale : Float32
      target_fps : Float32
      frame_time_total : Float32
      system_time_total : Float32
      merge_time_total : Float32
      world_time_total : Float32
      world_time_total_raw : Float32
      frame_count_total : Int32
      merge_count_total : Int32
      pipeline_build_count_total : Int32
      systems_ran_frame : Int32
    end

    struct TermSet
      relation : UInt64
      mask : UInt8
      min_depth : Int32
      max_depth : Int32
    end

    struct TermID
      entity : UInt64
      name : UInt8*
      var : Int32 # TODO: enum
      set : TermSet
    end

    struct Term
      id : UInt64
      inout : Int32 # TODO: enum
      pred : TermID
      subj : TermID
      obj : TermID
      oper : Int32 # TODO: enum
      role : UInt64
      name : UInt8*
      index : Int32
      move : Bool
    end

    struct Iter
      world : WorldRef
      real_world : WorldRef
      system : UInt64
      event : UInt64
      event_id : UInt64
      self_entity : UInt64
      table : TableRef
      type : TypeRef
      other_table : TableRef
      ids : UInt64*
      columns : Int32*
      subjects : UInt64*
      sizes : Int32*
      ptrs : Void**
      variable_names : UInt8**
      variables : UInt64*
      match_indices : Int32**
      references : Void* # TODO: ecs_ref_t *
      terms : Term*
      table_count : Int32
      term_count : Int32
      term_index : Int32
      variable_count : Int32
      entities : UInt64*
      param : Void*
      ctx : Void*
      binding_ctx : Void*
      delta_time : Float32
      delta_system_time : Float32
      frame_offset : Int32
      offset : Int32
      count : Int32
      total_count : Int32
      bogus : Int32
      bogus2 : Int32
      bogus3 : Int32
      is_value : Bool
      triggered_by : Void* # TODO: ecs_ids_t *
      interrupted_by : UInt64
      next_action : Void* # TODO: IterNextAction
      chain_it : Iter*

      # TODO: other fields in the struct that we don't currently use
    end

    type IterAction = Iter* -> Nil
    type IterNextAction = Iter* -> Void
    type OrderByAction = (
      UInt64,
      Void*,
      UInt64,
      Void*,
    ) -> Void
    type GroupByAction = (
      WorldRef,
      TypeRef, # TODO: Type
      UInt64,
      Void*,
    ) -> Void
    type SystemStatusAction = (
      WorldRef,
      UInt64,
      Int32, # TODO: enum
    ) -> Void
    type CtxFreeAction = Void* -> Void

    ECS_MAX_ADD_REMOVE = 32
    ECS_TERM_DESC_CACHE_SIZE = 16

    struct EntityDesc
      entity : UInt64
      name : UInt8*
      sep : UInt8*
      root_sep : UInt8*
      symbol : UInt8*
      use_low_id : Bool
      add : UInt64[ECS_MAX_ADD_REMOVE]
      add_expr : UInt8*
    end

    struct ComponentDesc
      entity : EntityDesc
      size : LibC::SizeT
      alignment : LibC::SizeT
    end

    struct FilterDesc
      terms : Term[ECS_TERM_DESC_CACHE_SIZE]
      terms_buffer : Term*
      terms_buffer_count : Int32
      substitute_default : Bool
      expr : UInt8*
      name : UInt8*
    end

    struct QueryDesc
      filter : FilterDesc
      order_by_component : UInt64
      order_by : Void* # TODO: OrderByAction
      group_by_id : UInt64
      group_by : Void* # TODO: GroupByAction
      group_by_ctx : Void*
      group_by_ctx_free : Void* # TODO: CtxFreeAction
      parent : QueryRef
      system : UInt64
    end

    struct SystemDesc
      entity : EntityDesc
      query : QueryDesc
      callback : Iter* -> # TODO: IterAction
      status_callback : Void* # TODO: SystemStatusAction
      self_entity : UInt64
      ctx : Void*
      status_ctx : Void*
      binding_ctx : Void*
      ctx_free : CtxFreeAction
      status_ctx_free : CtxFreeAction
      binding_ctx_free : CtxFreeAction
      interval : Float32
      rate : Int32
      tick_source : UInt64
    end

    fun init = ecs_init() : WorldRef

    fun fini = ecs_fini(world : WorldRef) : Int32

    fun get_world_info = ecs_get_world_info(world : WorldRef) : WorldInfo*

    fun set_target_fps = ecs_set_target_fps(world : WorldRef, fps : Float32)

    fun entity_init = ecs_entity_init(
      world : WorldRef,
      desc : EntityDesc*,
    ) : UInt64

    fun make_pair = ecs_make_pair(
      relation : UInt64,
      object : UInt64,
    ) : UInt64

    fun lookup = ecs_lookup(world : WorldRef, name : UInt8*) : UInt64

    fun component_init = ecs_component_init(
      world : WorldRef,
      desc : ComponentDesc*,
    ) : UInt64

    fun system_init = ecs_system_init(
      world : WorldRef,
      desc : SystemDesc*,
    ) : UInt64

    fun get_id = ecs_get_id(
      world : WorldRef,
      entity : UInt64,
      id : UInt64,
    ) : Void*

    fun set_id = ecs_set_id(
      world : WorldRef,
      entity : UInt64,
      id : UInt64,
      size : LibC::SizeT,
      ptr : Void*,
    ) : UInt64

    fun remove_id = ecs_remove_id(
      world : WorldRef,
      entity : UInt64,
      id : UInt64,
    ) : UInt64

    fun progress = ecs_progress(
      world : WorldRef,
      delta_time : Float32,
    ) : Bool
  end
end
