package aabb_editor

import "core:math"
import "core:math/linalg"

camera_projection :: enum {
    PERSPECTIVE,
    ORTHOGRAPHIC,
}

camera :: struct {
    fov, clip_near, clip_far : f32,
    pos, forward, up, right : vec3,
    rot : quaternion128,
    projection_matrix, view_matrix : mat4,
    projection : camera_projection,
}

make_default_cam :: proc () -> camera {
    forward := vec3{0.0, 0.0, -1.0}
    up :=  vec3 {0.0, 1.0, 0.0}
    right := vec3 {1.0, 0.0, 0.0}
    return {
        fov         = 60.0,
        clip_near   = 0.1,
        clip_far    = 100.0,
        pos         = {-0.7, 2.0, 4.2},
        forward     = forward,
        right       = right,
        up          = up,
        rot         = linalg.quaternion_from_forward_and_up_f32(forward, up),
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
