package aabb_editor
import gl "vendor:OpenGL"

box_line_renderer_state :: struct {
    vao, vbo :u32,
}

make_box_line_renderer_state :: proc() -> box_line_renderer_state {
    return {}
}

init_box_line_renderer :: proc(box_line_renderer : ^box_line_renderer_state) {
    vertices := [?]f32 {
        //Bottom
        0.0,        0.0,        0.0,
        1.0,        0.0,        0.0,
        
        1.0,        0.0,        0.0,
        1.0,        0.0,        1.0,

        1.0,        0.0,        1.0,
        0.0,        0.0,        1.0,
        
        0.0,        0.0,        1.0,
        0.0,        0.0,        0.0,

        //Top
        0.0,        1.0,        0.0,
        1.0,        1.0,        0.0,
        
        1.0,        1.0,        0.0,
        1.0,        1.0,        1.0,

        1.0,        1.0,        1.0,
        0.0,        1.0,        1.0,
        
        0.0,        1.0,        1.0,
        0.0,        1.0,        0.0,

        //Connectors
        0.0,        0.0,        0.0,
        0.0,        1.0,        0.0,
        
        1.0,        0.0,        0.0,
        1.0,        1.0,        0.0,

        1.0,        0.0,        1.0,
        1.0,        1.0,        1.0,
        
        0.0,        0.0,        1.0,
        0.0,        1.0,        1.0,

    }

    gl.GenVertexArrays(1, &box_line_renderer.vao)
    gl.GenBuffers(1, &box_line_renderer.vbo)

    gl.BindVertexArray(box_line_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, box_line_renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
}

cleanup_box_line_renderer :: proc(box_line_renderer : ^box_line_renderer_state) {
    gl.DeleteVertexArrays(1, &box_line_renderer.vao)
    gl.DeleteBuffers(1, &box_line_renderer.vbo)
}

draw_box_line_renderer :: proc(pos, scale, color : vec3, box_line_renderer : ^box_line_renderer_state, cam : ^camera, shader_state : ^global_shader_state) {
    model : mat4 = create_model_matrix(pos, scale)

    gl.UseProgram(shader_state.unlit_color_shader.id)
    gl.Uniform3f(shader_state.unlit_color_shader_color_location, color.x, color.y, color.z)
    gl.UniformMatrix4fv(shader_state.unlit_color_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(shader_state.unlit_color_view_location, 1, false, &cam.view_matrix[0][0])
    gl.UniformMatrix4fv(shader_state.unlit_color_projection_location, 1, false, &cam.projection_matrix[0][0])
    
    gl.BindVertexArray(box_line_renderer.vao)
    gl.DrawArrays(gl.LINES, 0, 24)
}