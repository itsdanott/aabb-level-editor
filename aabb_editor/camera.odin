package aabb_editor

import "core:math"
import "core:math/linalg"

cam_projection, cam_view : matrix[4,4]f32
cam_clip_near, cam_clip_far : f32 = 0.1, 100.0

cam_fov : f32 = 60.0
cam_pos : vec3 = {9.0, 2.0, 20.0}
cam_forward : vec3 = {0.0, 0.0, -1.0}
cam_up : vec3 = {0.0, 1.0, 0.0}

update_camera_matrices :: proc (){
    cam_projection = linalg.matrix4_perspective(math.to_radians(cam_fov), framebuffer_aspect, cam_clip_near, cam_clip_far)
    cam_view = linalg.matrix4_look_at_f32(Vec3(cam_pos), Vec3(cam_pos) + Vec3(cam_forward), Vec3(cam_up))
}
