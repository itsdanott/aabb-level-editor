package aabb_editor
import gl "vendor:OpenGL"

box_line_renderer_vao, box_line_renderer_vbo : u32

init_box_line_renderer :: proc() {
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

    gl.GenVertexArrays(1, &box_line_renderer_vao)
    gl.GenBuffers(1, &box_line_renderer_vbo)

    gl.BindVertexArray(box_line_renderer_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, box_line_renderer_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
}

cleanup_box_line_renderer :: proc() {
    gl.DeleteVertexArrays(1, &box_line_renderer_vao)
    gl.DeleteBuffers(1, &box_line_renderer_vbo)
}

draw_box_line_renderer :: proc(pos, scale, color : vec3) {
    model : matrix[4,4]f32 = create_model_matrix(pos, scale)

    gl.UseProgram(unlit_color_shader.id)
    gl.Uniform3f(unlit_color_shader_color_location, color.x, color.y, color.z)
    gl.UniformMatrix4fv(unlit_color_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(unlit_color_view_location, 1, false, &cam_view[0][0])
    gl.UniformMatrix4fv(unlit_color_projection_location, 1, false, &cam_projection[0][0])
    
    gl.BindVertexArray(box_line_renderer_vao)
    gl.DrawArrays(gl.LINES, 0, 24)
}