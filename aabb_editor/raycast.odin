package aabb_editor

ray :: struct {
    origin, direction : vec3,
}

ray_aabb_intersection_result :: struct {
    is_hit : bool,
    hit_point : vec3,
    t : f32,
    hit_face_index : i32,
}

ray_aabb_intersection :: proc (ray : ray, aabb : aabb) -> (result: ray_aabb_intersection_result, is_hit : bool)  {

    //todo: fix divided by zero
    t1 := f32 (aabb.min.x - ray.origin.x) / ray.direction.x
    t2 := f32 (aabb.max.x - ray.origin.x) / ray.direction.x
    t3 := f32 (aabb.min.y - ray.origin.y) / ray.direction.y
    t4 := f32 (aabb.max.y - ray.origin.y) / ray.direction.y
    t5 := f32 (aabb.min.z - ray.origin.z) / ray.direction.z
    t6 := f32 (aabb.max.z - ray.origin.z) / ray.direction.z


    t_min : f32 = max(max(min(t1, t2), min(t3, t4)), min(t5, t6))
    t_max : f32 = min(min(max(t1, t2), max(t3, t4)), max(t5, t6))

    if t_max < 0 || t_min > t_max do return result, false

    result.is_hit = true
    result.t = t_min

    result.hit_point.x = ray.origin.x + t_min * ray.direction.x
    result.hit_point.y = ray.origin.y + t_min * ray.direction.y
    result.hit_point.z = ray.origin.z + t_min * ray.direction.z

    if t_min == t1 do result.hit_face_index = 0 // -X face
    else if t_min == t2 do result.hit_face_index = 1 // +X face
    else if t_min == t3 do result.hit_face_index = 2 // -Y face
    else if t_min == t4 do result.hit_face_index = 3 // +Y face
    else if t_min == t5 do result.hit_face_index = 4 // -Z face
    else if t_min == t6 do result.hit_face_index = 5 // +Z face

    return result, true
}

//TODO: this will iterate over all AABBs later on 
// raycast_check_aabb :: proc(ray : ray, brushes ) -> (result : ray_aabb_intersection_result, is_hit : bool) {
//     aabb_
// }