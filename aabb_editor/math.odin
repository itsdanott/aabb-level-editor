package aabb_editor

import "core:math/linalg"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// math - types
vec2 :: [2]f32
vec3 :: [3]f32
vec4 :: [4]f32
mat4 :: matrix[4,4]f32

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// math - procs
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