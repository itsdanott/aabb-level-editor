package aabb_editor
import "core:math/linalg"
import "core:math"
import "vendor:glfw"

ray :: struct {
    origin, direction : vec3,
}

ray_aabb_intersection_result :: struct {
    is_hit : bool,
    hit_point : vec3,
    t : f32,
    hit_face_index : i32,
}

plane :: struct {
    normal : vec3,
    distance : f32,
}

get_snapped_world_pos_from_mouse_pos :: proc(state : ^app_state) -> vec3 {
    world_pos := get_world_pos_from_mouse_pos(state)
    world_pos_snapped := vec3{ math.floor(world_pos.x),math.floor(world_pos.y), math.floor(world_pos.z)}
    return world_pos_snapped
}

get_mouse_pos :: proc () -> (mouse_x, mouse_y : f32) {
    mouse_x64, mouse_y64 := glfw.GetCursorPos(glfw_window)
    when ODIN_OS == .Darwin {
        x_scale, y_scale := glfw.GetWindowContentScale(glfw_window)
        mouse_x64 *= f64(x_scale)
        mouse_y64 *= f64(y_scale)
    }
    return f32(mouse_x64), f32(mouse_y64)
}

get_world_space_from_mouse_pos :: proc(state : ^app_state) -> vec4 {
    mouse_x, mouse_y := get_mouse_pos()
    ncd_x : f32 = 2.0 * (f32(mouse_x) / f32(framebuffer_size_x)) - 1.0
    ndc_y : f32 = 1.0 - 2.0 * (f32(mouse_y) / f32(framebuffer_size_y))
    
    clip_space : vec4 = {ncd_x, ndc_y, -1.0, 1.0}
    inverse_projection : mat4 = linalg.matrix4_inverse_f32(state.camera.projection_matrix)
    eye_space : vec4 = inverse_projection * clip_space
    eye_space = vec4 {eye_space.x, eye_space.y, -1.0, 1.0}
    
    inverse_view : mat4 = linalg.matrix4_inverse_f32(state.camera.view_matrix)
    world_space : vec4 = inverse_view * eye_space

    return world_space
}

get_world_pos_from_mouse_pos :: proc(state : ^app_state) -> vec3 {
    world_space := get_world_space_from_mouse_pos(state)
    world_pos : vec3 = world_space.xyz / world_space.w
    
    return world_pos
}

get_ray_from_mouse_pos :: proc(state : ^app_state) -> ray {
    world_pos := get_world_pos_from_mouse_pos(state)

    ray_direction := linalg.vector_normalize(world_pos - state.camera.pos)
    ray := ray {
        origin = state.camera.pos,
        direction = ray_direction,
    }

    return ray
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

    if t_min == t1 do result.hit_face_index = AABB_FACE_INDEX_X_NEGATIVE
    else if t_min == t2 do result.hit_face_index = AABB_FACE_INDEX_X_POSITIVE
    else if t_min == t3 do result.hit_face_index = AABB_FACE_INDEX_Y_NEGATIVE
    else if t_min == t4 do result.hit_face_index = AABB_FACE_INDEX_Y_POSITIVE
    else if t_min == t5 do result.hit_face_index = AABB_FACE_INDEX_Z_NEGATIVE
    else if t_min == t6 do result.hit_face_index = AABB_FACE_INDEX_Z_POSITIVE

    return result, true
}

//un-tested
// raycast_plane :: proc (ray : ray, plane : plane) -> f32 {
//     nd := linalg.dot(ray.direction, plane.normal)
//     pn := linalg.dot(ray.origin, plane.normal)
//     if nd >= 0.0 do return -1.0

//     t := (plane.distance - pn) / nd
//     if t >= 0.0 do return t

//     return -1.0
// }

get_xz_plane_intersection_from_mouse_pos :: proc (state : ^app_state, plane_y : f32 = 0.0, positive_traversal_only : bool = false) -> (intersection : vec3, has_intersection:bool) {
    ray := get_ray_from_mouse_pos(state)    

    if ray.direction.y == 0.0 do return {}, false //ray is parallel to the plane
    t := (plane_y-ray.origin.y) / ray.direction.y    
    
    if positive_traversal_only && t < 0.0 do return {}, false //ray intersection is in negtaive direction

    intersection = ray.origin + t * ray.direction
    intersection.y = plane_y

    return intersection, true
}

get_xy_plane_intersection_from_mouse_pos :: proc (state : ^app_state,  plane_z : f32 = 0.0, positive_traversal_only : bool = false) -> (intersection : vec3, has_intersection:bool) {
    ray := get_ray_from_mouse_pos(state)    

    if ray.direction.z == 0.0 do return {}, false //ray is parallel to the plane
    t := (plane_z-ray.origin.z) / ray.direction.z

    if positive_traversal_only && t < 0.0 do return {}, false //ray intersection is in negative direction

    intersection = ray.origin + t * ray.direction
    intersection.z = plane_z

    return intersection, true
}

get_zy_plane_intersection_from_mouse_pos :: proc (state : ^app_state,  plane_x : f32 = 0.0, positive_traversal_only : bool = false) -> (intersection : vec3, has_intersection:bool) {
    ray := get_ray_from_mouse_pos(state)    

    if ray.direction.x == 0.0 do return {}, false //ray is parallel to the plane
    t := (plane_x-ray.origin.x) / ray.direction.x

    if positive_traversal_only && t < 0.0 do return {}, false //ray intersection is in negative direction

    intersection = ray.origin + t * ray.direction
    intersection.x = plane_x

    return intersection, true
}