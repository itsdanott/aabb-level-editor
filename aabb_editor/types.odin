package aabb_editor
import "core:math/linalg"

delta_time : f32 : 1.0 / 60.0

vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
mat4 :: matrix[4,4]f32

max_brushes_per_level :: 1024

level_data :: struct {
    brushes : [max_brushes_per_level]aabb_brush,
}

aabb_brush :: struct { 
    position : vec3,
}

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
