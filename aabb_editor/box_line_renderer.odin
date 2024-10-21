package aabb_editor

import gl "vendor:OpenGL"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// box_line_renderer - types
box_line_renderer_state :: struct {
    vao, vbo :u32,
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// box_line_renderer - procs
make_box_line_renderer_state :: proc() -> box_line_renderer_state {
    return {}
}

init_box_line_renderer :: proc(state : ^app_state) {
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

    gl.GenVertexArrays(1, &state.box_line_renderer.vao)
    gl.GenBuffers(1, &state.box_line_renderer.vbo)

    gl.BindVertexArray(state.box_line_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.box_line_renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)
}

cleanup_box_line_renderer :: proc(state : ^app_state) {
    gl.DeleteVertexArrays(1, &state.box_line_renderer.vao)
    gl.DeleteBuffers(1, &state.box_line_renderer.vbo)
}

// Draw /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
draw_box_line_renderer :: proc(pos, scale, color : vec3, state : ^app_state) {
    model : mat4 = create_model_matrix(pos, scale)

    gl.UseProgram(state.shader.unlit_color_shader.id)
    gl.Uniform4f(state.shader.unlit_color_shader_color_location, color.r, color.g, color.b, 1.0)
    gl.UniformMatrix4fv(state.shader.unlit_color_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(state.shader.unlit_color_view_location, 1, false, &state.camera.view_matrix[0][0])
    gl.UniformMatrix4fv(state.shader.unlit_color_projection_location, 1, false, &state.camera.projection_matrix[0][0])
    
    gl.BindVertexArray(state.box_line_renderer.vao)
    gl.DrawArrays(gl.LINES, 0, 24)
}

draw_box_line_renderer_aabb :: proc (min, max, color : vec3, state : ^app_state) {
    pos := min
    scale := max - min
    draw_box_line_renderer(pos, scale, color, state)
}