package aabb_editor
import "core:math/linalg"
import "core:fmt"
import "vendor:glfw"
import "core:math"

box_cursor_mouse_mode :: enum {
    MOVE,
    BRUSH_SELECT,
    FACE_SELECT,
    FACE_EDIT,
}

box_cursor_move_mode :: enum {
    FACE_AXIS,
    PLANE,
}

box_cursor_state :: struct {
    mouse_mode : box_cursor_mouse_mode,
    move_mode : box_cursor_move_mode,
    min, max, face_pos, color : vec3,
    is_face_grabbing, is_move_grabbing : bool,
    selected_face_index : i32,
    face_grab_axis : vec3,
    camera_distance, camera_pitch, camera_yaw : f32,
}

make_box_cursor_state :: proc() -> box_cursor_state {
    return {
        min = {0,0,0},
        max = {1,1,1},
        color = {1,1,1},
    }
}

//start grab ----------------------------------------------------------------------------------------------------------

start_box_cursor_mouse_click :: proc (state : ^app_state) {
    ray := get_ray_from_mouse_pos(state)
    result : ray_aabb_intersection_result 
    is_hit : bool
    switch state.box_cursor.mouse_mode{
    case .MOVE, .FACE_SELECT, .FACE_EDIT:
        aabb := aabb { 
            min = state.box_cursor.min,
            max = state.box_cursor.max,
        }                
        result, is_hit = ray_aabb_intersection(ray, aabb)
        if is_hit do state.box_cursor.selected_face_index = result.hit_face_index
    case .BRUSH_SELECT:
        for brush in state.brushes {
            aabb := aabb { 
                min = brush.min,
                max = brush.max,
            }                
            result, is_hit = ray_aabb_intersection(ray, aabb)
            if is_hit {
                select_brush(brush, state)
                return
            }
        }

        deselect_brush(state)
    }
    
    if !is_hit do return

    switch state.box_cursor.mouse_mode {
    case .MOVE:
        start_box_cursor_move(state.box_cursor.selected_face_index, state)
    case .BRUSH_SELECT:
        return
    case .FACE_SELECT:
        start_box_cursor_face_select(state.box_cursor.selected_face_index, state)
    case .FACE_EDIT:
        fmt.print("Start face editing")
        start_box_cursor_face_grabbing(ray, result, state)
    case:
        fmt.panicf("box_cursor_mouse_mode not implemented: %s", state.box_cursor.mouse_mode)
    }
}

start_box_cursor_move :: proc (face_index : i32, state : ^app_state) {

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

//update grab---------------------------------------------------------------------------------------------------------------
update_box_cursor_grabbing :: proc (state : ^app_state) {
    switch state.box_cursor.mouse_mode{
    case .MOVE:
        update_box_cursor_move_grab(state)
    case .FACE_SELECT:
        return
    case .FACE_EDIT:
        update_box_cursor_face_edit(state)
    case .BRUSH_SELECT:
        return
    }
}

@(private="file")
get_grab_key_input :: proc () -> (esc_key_pressed, snap_key_pressed : bool){
    return glfw.GetKey(glfw_window, glfw.KEY_ESCAPE) == glfw.PRESS,
    glfw.GetKey(glfw_window, glfw.KEY_LEFT_CONTROL) == glfw.PRESS
}

@(private="file")
update_box_cursor_move_grab :: proc (state : ^app_state){ 
    esc_key_pressed, snap_key_pressed := get_grab_key_input()
    // xy_intersection, has_xy_intersection := get_xy_plane_intersection_from_mouse_pos(state, state.box_cursor.min.z, false)           
    xz_intersection, has_xz_intersection := get_xz_plane_intersection_from_mouse_pos(state, state.box_cursor.min.y, false)           
    
    if has_xz_intersection {
        scale := state.box_cursor.max - state.box_cursor.min
        state.box_cursor.min = snap_key_pressed ? vec3{math.floor(xz_intersection.x), math.floor(xz_intersection.y), math.floor(xz_intersection.z)} : xz_intersection
        state.box_cursor.max = state.box_cursor.min + scale
    }
}

@(private="file")
update_box_cursor_face_edit :: proc (state : ^app_state){
    if !state.box_cursor.is_face_grabbing do return 

    esc_key_pressed, snap_key_pressed := get_grab_key_input()
    if esc_key_pressed {
        state.box_cursor.is_face_grabbing = false
    } else {           
        switch state.box_cursor.selected_face_index {
        case 0..<2: //X
            xy_intersection, has_xy_intersection := get_xy_plane_intersection_from_mouse_pos(state, state.box_cursor.min.z, false)           
            if has_xy_intersection do state.box_cursor.face_pos.x = snap_key_pressed ? math.floor(xy_intersection.x) : xy_intersection.x
        case 2..<4: //Y
            xy_intersection, has_xy_intersection := get_xy_plane_intersection_from_mouse_pos(state, state.box_cursor.min.z, false)           
            if has_xy_intersection do state.box_cursor.face_pos.y = snap_key_pressed ? math.floor(xy_intersection.y) : xy_intersection.y
        case 4..<6: //Z
            zy_intersection, has_zy_intersection := get_zy_plane_intersection_from_mouse_pos(state, state.box_cursor.min.x, false)           
            if has_zy_intersection do state.box_cursor.face_pos.z = snap_key_pressed ? math.floor(zy_intersection.z) : zy_intersection.z
        case: panic("aabb face index out of range!")
        }
    }
}

//finish grab-------------------------------------------------------------------------------------------------------------
finish_box_cursor_grabbing :: proc(state : ^app_state) {
    switch state.box_cursor.mouse_mode {
    case .MOVE:
        return
    case .BRUSH_SELECT:
            return
    case .FACE_SELECT:
        return
    case .FACE_EDIT:
        finish_box_cursor_face_grab(state)
    }
}

finish_box_cursor_face_grab :: proc (state : ^app_state) {
    if !state.box_cursor.is_face_grabbing do return 

    state.box_cursor.is_face_grabbing = false

    cursor := state.box_cursor.face_pos
    min := state.box_cursor.min
    max := state.box_cursor.max            

    switch state.box_cursor.selected_face_index {
    case AABB_FACE_INDEX_X_NEGATIVE:
        if cursor.x < max.x do state.box_cursor.min.x = cursor.x
        else{
            state.box_cursor.min.x = min.x
            state.box_cursor.max.x = cursor.x
        }
    case AABB_FACE_INDEX_X_POSITIVE:
        if cursor.x > min.x do state.box_cursor.max.x = cursor.x
        else{
            state.box_cursor.min.x = cursor.x
            state.box_cursor.max.x = min.x
        } 

    case AABB_FACE_INDEX_Y_NEGATIVE:
        if cursor.y < max.y do state.box_cursor.min.y = cursor.y
        else{
            state.box_cursor.min.y = min.y
            state.box_cursor.max.y = cursor.y
        }
    case AABB_FACE_INDEX_Y_POSITIVE:
        if cursor.y > min.y do state.box_cursor.max.y = cursor.y
        else{
            state.box_cursor.min.y = cursor.y
            state.box_cursor.max.y = min.y
        } 
    
    case AABB_FACE_INDEX_Z_NEGATIVE:
        if cursor.z < max.z do state.box_cursor.min.z = cursor.z
        else{
            state.box_cursor.min.z = min.z
            state.box_cursor.max.z = cursor.z
        }
    case AABB_FACE_INDEX_Z_POSITIVE:
        if cursor.z > min.z do state.box_cursor.max.z = cursor.z
        else{
            state.box_cursor.min.z = cursor.z
            state.box_cursor.max.z = min.z
        } 
    case: panic("aabb face index out of range!")
    }
}

//draw ---------------------------------------------------------------------------------------------
@(private="file")
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
    draw_box_line_renderer_aabb(state.box_cursor.min, state.box_cursor.max, state.box_cursor.color, state)

    switch state.box_cursor.mouse_mode {
    case .MOVE:
        return
    case .BRUSH_SELECT:
        return
    case .FACE_SELECT:
        draw_box_cursor_face_select(state)
    case .FACE_EDIT:
        draw_box_cursor_face_grabbing(state)
    }
}

@(private="file")
draw_box_cursor_face_select :: proc(state : ^app_state) {
    rot : quaternion128 = get_quad_rot_from_face_index(state.box_cursor.selected_face_index)
    scale := state.box_cursor.max - state.box_cursor.min
    state.box_cursor.face_pos = get_cursor_face_pos_from_face_index(state.box_cursor.selected_face_index, state)
    quad := quad_handle {
        pos = state.box_cursor.face_pos,
        color = state.box_cursor.face_grab_axis,
        scale = scale,
        rot = rot,
        alpha = 0.5,  
    }
    draw_quad_renderer(quad, state)
}

@(private="file")
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
        alpha = 0.75,        
    }
    draw_quad_renderer(quad, state)
}

@(private="file")
get_quad_rot_from_face_index :: proc (face_index : i32) -> quaternion128 {
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