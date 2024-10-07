package aabb_editor

import "core:math"
import "core:math/linalg"
import gl "vendor:OpenGL"

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

    cam.projection_matrix = linalg.matrix4_perspective(math.to_radians(cam.fov), framebuffer_aspect, cam.clip_near, cam.clip_far)
    cam.view_matrix = view_matrix
}