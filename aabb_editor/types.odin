package aabb_editor

vec3 :: [3]f32
mat4 :: matrix[4,4]f32
import "core:math/linalg"

max_brushes_per_level :: 1024

level_data :: struct {
    brushes : [max_brushes_per_level]aabb_brush,
}

aabb_brush :: struct { 
    position : vec3,
}

ray :: struct {
    origin : vec3,
}

create_model_matrix :: proc (pos : vec3, scale : vec3) -> mat4 {
    model_matrix := linalg.matrix4_translate_f32(pos)
    model_matrix *= linalg.matrix4_scale_f32(scale)
    return model_matrix
}