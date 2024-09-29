package aabb_editor
import "core:math/linalg"
import "core:fmt"

box_cursor_grab_mode :: enum {
    MOVE,
    FACE_SELECT,
    FACE_EDIT,
}
box_cursor_state :: struct {
    grab_mode : box_cursor_grab_mode,
    min, max, face_pos : vec3,
    is_face_grabbing, is_move_grabbing : bool,
    selected_face_index : i32,
    face_grab_axis : vec3,
}

make_box_cursor_state :: proc() -> box_cursor_state {
    return {
        min = {0,0,0},
        max = {1,1,1},
    }
}
start_box_cursor_grabbing :: proc (ray : ray, raycast_result : ray_aabb_intersection_result, state : ^app_state) {
    state.box_cursor.selected_face_index = raycast_result.hit_face_index
    switch state.box_cursor.grab_mode {
    case .MOVE:
        fmt.print("Start moving")
    case .FACE_SELECT:
        start_box_cursor_face_select(state.box_cursor.selected_face_index, state)
    case .FACE_EDIT:
        fmt.print("Start face editing")
        start_box_cursor_face_grabbing(ray, raycast_result, state)
    case:
        fmt.panicf("box_cursor_grab_mode not implemented: %s", state.box_cursor.grab_mode)
    }
}

start_box_cursor_face_select :: proc (face_index : i32, state : ^app_state) {
    state.box_cursor.face_grab_axis = aabb_face_index_to_axis(face_index)
}
start_box_cursor_face_grabbing :: proc (ray : ray, raycast_result : ray_aabb_intersection_result, state : ^app_state) {
    state.box_cursor.is_face_grabbing = true
    axis := aabb_face_index_to_axis(raycast_result.hit_face_index)
    state.box_cursor.face_grab_axis = axis
    scale := state.box_cursor.max - state.box_cursor.min
    state.box_cursor.face_pos = get_cursor_face_pos_from_face_index(state.box_cursor.selected_face_index, state)
    
    // fmt.println("Index:", raycast_result.hit_face_index)

    // add_line_render_handle({
    //     from = ray.origin,
    //     to = raycast_result.hit_point,
    //     color = axis,
    //     life_time = 1.0,
    // }, state)
}

@private
get_cursor_face_pos_from_face_index :: proc(face_index : i32, state : ^app_state) -> vec3 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE,
        AABB_FACE_INDEX_Y_NEGATIVE,
        AABB_FACE_INDEX_Z_NEGATIVE:
        return state.box_cursor.min
    case AABB_FACE_INDEX_X_POSITIVE,
        AABB_FACE_INDEX_Y_POSITIVE,
        AABB_FACE_INDEX_Z_POSITIVE:
        return state.box_cursor.max
    case: 
        panic("invalid face Index")
    }
}

draw_box_cursor :: proc(state : ^app_state) {

    draw_box_line_renderer_aabb(state.box_cursor.min, state.box_cursor.max, vec3{1.0, 1.0, 1.0}, state)

    switch state.box_cursor.grab_mode {
    case .MOVE:

    case .FACE_SELECT:
        draw_box_cursor_face_select(state)
    case .FACE_EDIT:
        draw_box_cursor_face_grabbing(state)
    }
}

@private 
draw_box_cursor_face_select :: proc(state : ^app_state) {
    rot : quaternion128 = get_quad_rot_from_face_index(state.box_cursor.selected_face_index)
    scale := state.box_cursor.max - state.box_cursor.min
    state.box_cursor.face_pos = get_cursor_face_pos_from_face_index(state.box_cursor.selected_face_index, state)
    quad := quad_handle {
        pos = state.box_cursor.face_pos,
        color = state.box_cursor.face_grab_axis,
        scale = scale,
        rot = rot,            
    }
    draw_quad_renderer(quad, state)
}

@private 
draw_box_cursor_face_grabbing :: proc(state : ^app_state) {
    if !state.box_cursor.is_face_grabbing do return    
    rot : quaternion128 = get_quad_rot_from_face_index(state.box_cursor.selected_face_index)
    plane_normal : vec3
    scale := state.box_cursor.max - state.box_cursor.min

    

    quad := quad_handle {
        pos = state.box_cursor.face_pos,
        color = state.box_cursor.face_grab_axis,
        scale = scale,
        rot = rot,            
    }
    draw_quad_renderer(quad, state)
}

@private get_quad_rot_from_face_index :: proc (face_index : i32) -> quaternion128 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE:
        return linalg.quaternion_from_forward_and_up_f32({ 0,  0, -1}, {-1,  0,  0})
    case AABB_FACE_INDEX_X_POSITIVE:
        return linalg.quaternion_from_forward_and_up_f32({ 0,  0,  1}, {-1,  0,  0})
    case AABB_FACE_INDEX_Y_NEGATIVE:
        return linalg.quaternion_from_forward_and_up_f32({ 0,  0, -1}, { 0,  1,  0})
    case AABB_FACE_INDEX_Y_POSITIVE:
        return linalg.quaternion_from_forward_and_up_f32({ 0,  0,  1}, { 0,  1,  0})
    case AABB_FACE_INDEX_Z_NEGATIVE:
        return linalg.quaternion_from_forward_and_up_f32({-1,  0,  0}, { 0,  0,  1})
    case AABB_FACE_INDEX_Z_POSITIVE:
        return linalg.quaternion_from_forward_and_up_f32({ 1,  0,  0}, { 0,  0,  1})
    case:
        panic("invalid selected_face_index")
    }
}