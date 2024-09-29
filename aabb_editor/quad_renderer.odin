package aabb_editor

import gl "vendor:OpenGL"
import "core:math/linalg"

quad_renderer_state :: struct {
    vao, vbo : u32,
}

quad_handle :: struct {
    pos, scale, color : vec3, 
    rot : quaternion128,
}

make_quad_renderer_state :: proc () -> quad_renderer_state {
    return {}
}

init_quad_renderer :: proc(state : ^app_state) {
    gl.GenVertexArrays(1, &state.quad_renderer.vao)
    gl.GenBuffers(1, &state.quad_renderer.vbo)

    gl.BindVertexArray(state.quad_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.quad_renderer.vbo)

    vertices := [?]f32 {
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 0.0,
    }
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
}

cleanup_quad_renderer :: proc(state : ^app_state){
    gl.DeleteVertexArrays(1, &state.quad_renderer.vao)
    gl.DeleteBuffers(1, &state.quad_renderer.vbo)
}

draw_quad_renderer :: proc (quad : quad_handle, state : ^app_state) {
    model : mat4 = create_model_matrix_rot(quad.pos, quad.scale, quad.rot)
    gl.UseProgram(state.shader.unlit_color_shader.id)
    
    gl.Uniform3f(state.shader.unlit_color_shader_color_location, quad.color.r, quad.color.g, quad.color.b)
    gl.UniformMatrix4fv(state.shader.unlit_color_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(state.shader.unlit_color_view_location, 1, false, &state.camera.view_matrix[0][0])
    gl.UniformMatrix4fv(state.shader.unlit_color_projection_location, 1, false, &state.camera.projection_matrix[0][0])
    
    gl.BindVertexArray(state.quad_renderer.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}