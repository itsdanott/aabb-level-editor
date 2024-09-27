package aabb_editor
import gl "vendor:OpenGL"

grid_state :: struct {
    pos, scale : vec3,
    vao, vbo : u32,
    shader : ^shader,
    shader_model_location : i32,
    shader_view_location : i32,
    shader_projection_location : i32,
    shader_view_pos_location : i32,
    shader_grid_scale_location : i32,
}

make_grid_state :: proc() -> grid_state {
    return grid_state{
        scale = {32.0, 1.0, 32.0},
    }
}

init_grid :: proc(grid : ^grid_state) -> bool {
    shader_success : bool
    grid.shader, shader_success = load_shader_from_files("shaders/grid.vert.glsl", "shaders/grid.frag.glsl")
    if !shader_success do return false

    grid.shader_model_location = gl.GetUniformLocation(grid.shader.id, "model")
    grid.shader_view_location = gl.GetUniformLocation(grid.shader.id, "view")
    grid.shader_projection_location = gl.GetUniformLocation(grid.shader.id, "projection")
    grid.shader_view_pos_location = gl.GetUniformLocation(grid.shader.id, "viewPos")
    grid.shader_grid_scale_location = gl.GetUniformLocation(grid.shader.id, "gridScale")

    vertices := [?]f32 {
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 0.0,
    }

    gl.GenVertexArrays(1, &grid.vao)
    gl.GenBuffers(1, &grid.vbo)

    gl.BindVertexArray(grid.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, grid.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)

    return true
}

cleanup_grid :: proc(grid : ^grid_state) {
    gl.DeleteVertexArrays(1, &grid.vao)
    gl.DeleteBuffers(1, &grid.vbo)
    free_shader(grid.shader)
}

draw_grid :: proc(grid : ^grid_state, cam : ^camera) {
    grid.pos = {cam.pos.x - grid.scale.x * 0.5, 0, cam.pos.z  - grid.scale.z * 0.5}
    model : mat4 = create_model_matrix(grid.pos,grid.scale)
    
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.UseProgram(grid.shader.id)
    gl.UniformMatrix4fv(grid.shader_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(grid.shader_view_location, 1, false, &cam.view_matrix[0][0])
    gl.UniformMatrix4fv(grid.shader_projection_location, 1, false, &cam.projection_matrix[0][0])
    gl.Uniform3f(grid.shader_view_pos_location, cam.pos.x, cam.pos.y, cam.pos.z)
    gl.Uniform1f(grid.shader_grid_scale_location, 1.0)
    gl.BindVertexArray(grid.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.Disable(gl.BLEND)
}
