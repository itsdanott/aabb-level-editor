package aabb_editor
import "core:math/linalg"

delta_time : f32 : 1.0 / 60.0

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

create_model_matrix :: proc (pos : vec3, scale : vec3) -> mat4 {
    model_matrix := linalg.matrix4_translate_f32(pos)
    model_matrix *= linalg.matrix4_scale_f32(scale)
    return model_matrix
}

aabb_face_index_to_color :: proc (face_index : i32) -> vec3 {
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