package aabb_editor

import "core:math"
import "core:math/linalg"

camera_projection :: enum {
    PERSPECTIVE,
    ORTHOGRAPHIC,
}

camera :: struct {
    fov, clip_near, clip_far : f32,
    pos, forward, up, centre : vec3,
    projection_matrix, view_matrix : mat4,
    projection : camera_projection,
}

make_default_cam :: proc () -> camera {
    return {
        fov         = 60.0,
        clip_near   = 0.1,
        clip_far    = 100.0,
        pos         = {9.0, 2.0, 20.0},
        forward     = {0.0, 0.0, -1.0},
        up          = {0.0, 1.0, 0.0},
        centre      = {0.0, 0.0, 0.0},
    }
}

update_camera_matrices :: proc (cam : ^camera ) {
    cam.projection_matrix = linalg.matrix4_perspective(math.to_radians(cam.fov), framebuffer_aspect, cam.clip_near, cam.clip_far)
    cam.centre = cam.pos + cam.forward
    cam.view_matrix = linalg.matrix4_look_at_f32(cam.pos, cam.centre, cam.up)
}
