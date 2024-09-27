package aabb_editor

vec3 :: struct {
    x, y, z : f32,
}

Vec3 :: proc (vec : vec3) -> [3]f32 {
    return {vec.x,vec.y,vec.z}
}

max_brushes_per_level :: 1024
level_data :: struct {
    brushes : [max_brushes_per_level]aabb_brush,
}

aabb_brush :: struct { 
    position : vec3,
}

camera :: struct { 

}
