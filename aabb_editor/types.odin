package aabb_editor
import "core:math/linalg"
import "core:math"

delta_time : f32 : 1.0 / 60.0

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
mat4 :: matrix[4,4]f32

aabb :: struct {
    min, max : vec3,
}

AABB_FACE_INDEX_X_NEGATIVE :: 0
AABB_FACE_INDEX_X_POSITIVE :: 1

AABB_FACE_INDEX_Y_NEGATIVE :: 2
AABB_FACE_INDEX_Y_POSITIVE :: 3

AABB_FACE_INDEX_Z_NEGATIVE :: 4
AABB_FACE_INDEX_Z_POSITIVE :: 5

app_state :: struct {
    editor : editor_state,
    grid : grid_state,
    shader : global_shader_state,
    camera : camera,
    line_renderer : line_renderer_state,
    box_line_renderer : box_line_renderer_state,
    quad_renderer : quad_renderer_state,
    box_cursor : box_cursor_state,
    textures : [dynamic]^texture,
    brushes : [dynamic]^brush,
    brush_renderer : brush_renderer_state,
    texture_array_id : u32,
    selected_brush : ^brush,
    unique_brush_id_increment : u32,
    is_mouse_hit : bool, //TODO: to be used to get the aabb edge points
    input : input_state,
    viewport_renderer : viewport_renderer_state,
}

make_app_state :: proc() -> app_state{
    return {
        editor = make_editor_state(),
        grid = make_grid_state(),
        shader = make_global_shader_state(),
        camera = make_default_cam(),
        line_renderer = make_line_renderer_state(),
        box_line_renderer = make_box_line_renderer_state(),
        quad_renderer = make_quad_renderer_state(),
        box_cursor = make_box_cursor_state(),
        brush_renderer = make_brush_renderer_state(),
        selected_brush = nil,
        input = make_input_state(),
        viewport_renderer = make_viewport_renderer_state(),
    }
}

create_model_matrix :: proc (pos : vec3, scale : vec3) -> mat4 {
    model_matrix := linalg.matrix4_translate_f32(pos)
    model_matrix *= linalg.matrix4_scale_f32(scale)
    return model_matrix
}

create_model_matrix_rot :: proc (pos : vec3, scale : vec3, rot : quaternion128) -> mat4 {
    model_matrix := linalg.matrix4_translate_f32(pos)
    model_matrix *= linalg.matrix4_scale_f32(scale)
    model_matrix *= linalg.matrix4_from_quaternion_f32(rot)
    return model_matrix
}

aabb_face_index_to_axis :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case 0..<2: //X
        return {1.0, 0.0, 0.0}
    case 2..<4: //Y
        return {0.0, 1.0, 0.0}
    case 4..<6: //Z
        return {0.0, 0.0, 1.0}
    case: panic("aabb face index out of range!")
    }
}

aabb_face_index_to_normal :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE: return vec3{-1,0,0}
    case AABB_FACE_INDEX_X_POSITIVE: return vec3{1,0,0}
    case AABB_FACE_INDEX_Y_NEGATIVE: return vec3{0,-1,0}
    case AABB_FACE_INDEX_Y_POSITIVE: return vec3{0,1,0}
    case AABB_FACE_INDEX_Z_NEGATIVE: return vec3{0,0,-1}
    case AABB_FACE_INDEX_Z_POSITIVE: return vec3{0,0,1}
    case: panic("aabb face index out of range!")
    }
}

aabb_face_index_to_perpendicular_plane_normal :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE:
        return {1,0,0}
    case AABB_FACE_INDEX_X_POSITIVE:
        return {1,0,0}
    case AABB_FACE_INDEX_Y_NEGATIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Y_POSITIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Z_NEGATIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Z_POSITIVE:
        return {0,0,1}
    case:
        panic("invalid selected_face_index")
    }
}

aabb_fix_min_max :: proc(aabb : ^aabb) {
    aabb^ = {
        min = vec3 {
            math.min(aabb.min.x, aabb.max.x),
            math.min(aabb.min.y, aabb.max.y),
            math.min(aabb.min.z, aabb.max.z),
        },
        max = vec3 {
            math.max(aabb.min.x, aabb.max.x),
            math.max(aabb.min.y, aabb.max.y),
            math.max(aabb.min.z, aabb.max.z),
        },
    }
}

aabb_get_size :: proc(aabb : aabb) -> vec3 {
    return aabb.max-aabb.min
}