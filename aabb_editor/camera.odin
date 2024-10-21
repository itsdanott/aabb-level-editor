package aabb_editor

import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// camera - types
camera_projection :: enum {
    PERSPECTIVE,
    ORTHOGRAPHIC,
}

camera :: struct {
    fov, clip_near, clip_far, pos_lerp_speed, rot_lerp_speed : f32,
    pos, forward, up, right, lerp_pos : vec3,
    rot, lerp_rot : quaternion128,
    projection_matrix, view_matrix : mat4,
    projection : camera_projection,
    clear_color : vec3,
    move_speed, rot_key_sensitivity, rot_mouse_sensitivity_x, rot_mouse_sensitivity_y, orbit_sensitivity : f32,
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// camera - procs
make_default_cam :: proc () -> camera {
    forward := vec3{0.0, 0.0, -1.0}
    up :=  vec3 {0.0, 1.0, 0.0}
    right := vec3 {1.0, 0.0, 0.0}
    pos := vec3 {-0.7, 2.0, 4.2}
    rot := linalg.quaternion_from_forward_and_up_f32(forward, up)
    return {
        fov         = 60.0,
        clip_near   = 0.1,
        clip_far    = 100.0,
        pos_lerp_speed = 16.0,
        rot_lerp_speed = 16.0,
        pos = pos,
        lerp_pos = pos,
        forward     = forward,
        right       = right,
        up          = up,
        rot         = rot,
        lerp_rot    = rot,
        clear_color  = {0.25, 0.25, 0.5},
        move_speed = 4.0,
        rot_key_sensitivity = 90.0,
        rot_mouse_sensitivity_x = 120.0,
        rot_mouse_sensitivity_y = 120.0,
        orbit_sensitivity = 4.0,
    }
}

update_camera_matrices :: proc (cam : ^camera ) {
    rotation_matrix := linalg.matrix4_from_quaternion_f32(cam.rot)
    translation_matrix := linalg.matrix4_translate_f32(-cam.pos)
    view_matrix := rotation_matrix * translation_matrix

    
    cam.forward = -linalg.vector_normalize(vec3{view_matrix[0][2], view_matrix[1][2], view_matrix[2][2]})
    cam.right = linalg.vector_normalize(vec3{view_matrix[0][0], view_matrix[1][0], view_matrix[2][0]})
    cam.up = linalg.vector_normalize(vec3{view_matrix[0][1], view_matrix[1][1], view_matrix[2][1]})

    cam.projection_matrix = linalg.matrix4_perspective(math.to_radians(cam.fov), framebuffer_aspect, cam.clip_near, 
        cam.clip_far)
    cam.view_matrix = view_matrix
}

camera_mouse_rotate_pitch_and_yaw :: proc (state : ^app_state) {
    if linalg.vector_length(state.editor.mouse_delta) > linalg.F32_EPSILON {
        pitch_angle : f32 = -state.editor.mouse_delta.y * state.camera.rot_mouse_sensitivity_y * delta_time
        yaw_angle : f32 = -state.editor.mouse_delta.x * state.camera.rot_mouse_sensitivity_x * delta_time
        
        yaw_quat : quaternion128 = linalg.quaternion_angle_axis_f32(
            linalg.to_radians(yaw_angle), vec3{0.0, 1.0, 0.0})
            
        pitch_quat : quaternion128 = linalg.quaternion_angle_axis_f32(
            linalg.to_radians(pitch_angle), state.camera.right)
        
        state.camera.lerp_rot = state.camera.lerp_rot * yaw_quat
        state.camera.lerp_rot = state.camera.lerp_rot * pitch_quat
        
        state.camera.lerp_rot = linalg.quaternion_normalize(state.camera.lerp_rot)

    }
    //TODO: fix roll rotation appearing when rot lerping
    //TODO: maybe lerp the yaw and pitch instead of the quat?
    // state.camera.rot = linalg.lerp(state.camera.rot, state.camera.lerp_rot, state.camera.rot_lerp_speed * delta_time)
    // state.camera.rot = linalg.quaternion_normalize(state.camera.rot)
    //this is the temporary hard setting of the value:
    state.camera.rot = state.camera.lerp_rot
}

camera_mouse_orbit :: proc (state : ^app_state) {
    camera_target := linalg.lerp(state.box_cursor.min, state.box_cursor.max, 0.5)
    if state.editor.input_cam_orbit.is_start_press {
        state.box_cursor.camera_distance = linalg.distance(camera_target, state.camera.pos)
        look_quat := linalg.quaternion_look_at_f32(state.camera.pos, camera_target, vec3{0.0,1.0,0.0} )
        //TODO: smooth the pitch and yaw transition
        // state.box_cursor.camera_pitch = linalg.pitch_from_quaternion(look_quat)
        // state.box_cursor.camera_yaw = linalg.yaw_from_quaternion(look_quat)
    } else /*if linalg.abs(glfw_scroll.y) > linalg.F32_EPSILON*/ do state.box_cursor.camera_distance = linalg.max(
        state.box_cursor.camera_distance -glfw_scroll.y, 0.5)
    
    if linalg.abs(state.editor.mouse_delta.x) > linalg.F32_EPSILON do state.box_cursor.camera_yaw +=
        state.editor.mouse_delta.x * state.camera.orbit_sensitivity * delta_time
        
    if linalg.abs(state.editor.mouse_delta.y) > linalg.F32_EPSILON do state.box_cursor.camera_pitch +=
        state.editor.mouse_delta.y * state.camera.orbit_sensitivity * delta_time

    state.box_cursor.camera_pitch = linalg.clamp(state.box_cursor.camera_pitch, -HALF_PI + linalg.F32_EPSILON,
        HALF_PI - linalg.F32_EPSILON)

    pitch := state.box_cursor.camera_pitch
    yaw := state.box_cursor.camera_yaw

    orbit_x := state.box_cursor.camera_distance * linalg.cos(pitch) * linalg.sin(yaw)
    orbit_y := state.box_cursor.camera_distance * linalg.sin(pitch)
    orbit_z := state.box_cursor.camera_distance * linalg.cos(pitch) * linalg.cos(yaw)

    state.camera.lerp_pos = camera_target + {orbit_x, orbit_y, orbit_z}
    state.camera.pos = linalg.lerp(state.camera.pos, state.camera.lerp_pos, state.camera.pos_lerp_speed * 
        delta_time)

    state.camera.rot = linalg.quaternion_look_at_f32(state.camera.pos, camera_target, vec3{0.0,1.0,0.0} )
    state.camera.lerp_rot = state.camera.rot
}