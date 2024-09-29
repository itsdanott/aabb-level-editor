package aabb_editor
import gl "vendor:OpenGL"
import "core:math"

grid_state :: struct {
    pos, scale : vec3,
    vao, vbo : u32,
    shader : ^shader,
    shader_model_location : i32,
    shader_view_location : i32,
    shader_projection_location : i32,
    shader_view_pos_location : i32,
    shader_grid_alpha_location : i32,
    shader_checker_col1_location, shader_checker_col2_location : i32,
    shader_grid_fade_dist_location : i32,
    checker_col1, checker_col2 : vec3, 
    grid_alpha, grid_fade_dist : f32,
}

make_grid_state :: proc() -> grid_state {
    return grid_state{
        scale = {100.0, 1.0, 100.0},
        grid_alpha = 0.125,
        grid_fade_dist = 32.0,
        checker_col1 = {0,0,0},
        checker_col2 = {1,1,1},
    }
}

init_grid :: proc(state : ^app_state) -> bool {
    shader_success : bool
    state.grid.shader, shader_success = load_shader_from_files("shaders/grid.vert.glsl", "shaders/grid.frag.glsl")
    if !shader_success do return false

    state.grid.shader_model_location = gl.GetUniformLocation(state.grid.shader.id, "model")
    state.grid.shader_view_location = gl.GetUniformLocation(state.grid.shader.id, "view")
    state.grid.shader_projection_location = gl.GetUniformLocation(state.grid.shader.id, "projection")
    state.grid.shader_view_pos_location = gl.GetUniformLocation(state.grid.shader.id, "viewPos")
    state.grid.shader_view_pos_location = gl.GetUniformLocation(state.grid.shader.id, "viewPos")
    state.grid.shader_grid_alpha_location = gl.GetUniformLocation(state.grid.shader.id, "gridAlpha")
    state.grid.shader_checker_col1_location = gl.GetUniformLocation(state.grid.shader.id, "checkerColor1")
    state.grid.shader_checker_col2_location = gl.GetUniformLocation(state.grid.shader.id, "checkerColor2")
    state.grid.shader_grid_fade_dist_location = gl.GetUniformLocation(state.grid.shader.id, "gridFadeDist")

    vertices := [?]f32 {
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 0.0,
    }

    gl.GenVertexArrays(1, &state.grid.vao)
    gl.GenBuffers(1, &state.grid.vbo)

    gl.BindVertexArray(state.grid.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.grid.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)

    return true
}

cleanup_grid :: proc(state : ^app_state) {
    gl.DeleteVertexArrays(1, &state.grid.vao)
    gl.DeleteBuffers(1, &state.grid.vbo)
    free_shader(state.grid.shader)
}

draw_grid :: proc(state : ^app_state) {
    // state.grid.pos = {state.editor.box1_pos.x - state.grid.scale.x * 0.5, math.floor(state.editor.box1_pos.y), state.editor.box1_pos.z - state.grid.scale.z * 0.5}
    state.grid.pos = vec3{state.camera.pos.x - state.grid.scale.x * 0.5, math.floor(state.editor.box1_pos.y), state.camera.pos.z- state.grid.scale.z * 0.5}
    model : mat4 = create_model_matrix(state.grid.pos, state.grid.scale)
    
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.UseProgram(state.grid.shader.id)
    gl.UniformMatrix4fv(state.grid.shader_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(state.grid.shader_view_location, 1, false, &state.camera.view_matrix[0][0])
    gl.UniformMatrix4fv(state.grid.shader_projection_location, 1, false, &state.camera.projection_matrix[0][0])
    gl.Uniform3f(state.grid.shader_view_pos_location, state.camera.pos.x, state.camera.pos.y, state.camera.pos.z)
    gl.Uniform3f(state.grid.shader_checker_col1_location, state.grid.checker_col1.r,state.grid.checker_col1.g, state.grid.checker_col1.b)
    gl.Uniform3f(state.grid.shader_checker_col2_location, state.grid.checker_col2.r,state.grid.checker_col2.g, state.grid.checker_col2.b)
    gl.Uniform1f(state.grid.shader_grid_alpha_location, state.grid.grid_alpha)
    gl.Uniform1f(state.grid.shader_grid_fade_dist_location, state.grid.grid_fade_dist)
    gl.BindVertexArray(state.grid.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.Disable(gl.BLEND)
}
