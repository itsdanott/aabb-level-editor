package aabb_editor

vec3 :: struct {
    x, y, z : f32,
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
