package aabb_editor

import gl "vendor:OpenGL"
import sa "core:container/small_array"
import "core:fmt"
import "core:math/linalg"
max_line_render_handle_count :: 32

line_render_handle :: struct {
    from, to, color : vec3,
    life_time : f32,
}

line_renderer_state :: struct {
    vao, vbo : u32,
    model_matrix : mat4,
    // lines : sa.Small_Array(max_line_render_handle_count, line_render_handle),
    lines : [dynamic]line_render_handle,
}

make_line_renderer_state :: proc () -> line_renderer_state{
    return {
        model_matrix = linalg.matrix4_translate(vec3{0,0,0}),//create_model_matrix({0,0,0}, {1,1,1}),
    }
}

init_line_renderer :: proc (line_renderer : ^line_renderer_state) {
    gl.GenVertexArrays(1, &line_renderer.vao)
    gl.GenBuffers(1, &line_renderer.vbo)

    gl.BindVertexArray(line_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, line_renderer.vbo)
    vertices := [6]vec3 {
        9.0, 2.0, 20.0,
        0.0, 0.0, 0.0,
    }
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * 6, &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)

    gl.LineWidth(8)
    // gl.Enable(gl.LINE_SMOOTH)
    reserve(&line_renderer.lines, max_line_render_handle_count)
}

cleanup_line_renderer :: proc (line_renderer : ^line_renderer_state) {
    gl.DeleteVertexArrays(1, &line_renderer.vao)
    gl.DeleteBuffers(1, &line_renderer.vbo)
}

add_line_render_handle :: proc(handle : line_render_handle, state : ^line_renderer_state) {
    if len(state.lines) >= max_line_render_handle_count do return
    append(&state.lines, handle)
}

draw_line_renderer :: proc (state : ^line_renderer_state, cam : ^camera, shader_state : ^global_shader_state) {
    num_lines := len(state.lines)
    if num_lines == 0 do return
    
    gl.UseProgram(shader_state.unlit_color_shader.id)
    gl.UniformMatrix4fv(shader_state.unlit_color_model_location, 1, false, &state.model_matrix[0][0])
    gl.UniformMatrix4fv(shader_state.unlit_color_view_location, 1, false, &cam.view_matrix[0][0])
    gl.UniformMatrix4fv(shader_state.unlit_color_projection_location, 1, false, &cam.projection_matrix[0][0])

    gl.BindVertexArray(state.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.vbo)

    for index:=0; index < len(state.lines); index+=1 {
        line := state.lines[index]

        vertices := [6]f32 {
            line.from.x, line.from.y, line.from.z,
            line.to.x, line.to.y, line.to.z,
        }


        gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * 6, &vertices, gl.STATIC_DRAW)
        
        gl.Uniform3f(shader_state.unlit_color_shader_color_location, line.color.x, line.color.y, line.color.z)
        
        gl.DrawArrays(gl.LINES, 0, 2)

        new_lifetime := line.life_time - delta_time
        if new_lifetime <= 0  {
            ordered_remove(&state.lines, index)
            index -= 1
        } else do state.lines[index].life_time = new_lifetime
    }
}