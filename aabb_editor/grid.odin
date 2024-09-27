package aabb_editor
import gl "vendor:OpenGL"
import "core:math/linalg"
import "core:math"

grid_shader : ^shader 
grid_vao, grid_vbo : u32

grid_shader_model_location : i32 = 0
grid_shader_view_location : i32 = 0
grid_shader_projection_location : i32 = 0
grid_shader_view_pos_location : i32 = 0
grid_shader_grid_scale_location : i32 = 0

init_grid :: proc() -> bool {
    gshader, shader_success := load_shader_from_files("shaders/grid.vert.glsl", "shaders/grid.frag.glsl")
    if !shader_success do return false
    grid_shader = gshader

    grid_shader_model_location = gl.GetUniformLocation(grid_shader.id, "model")
    grid_shader_view_location = gl.GetUniformLocation(grid_shader.id, "view")
    grid_shader_projection_location = gl.GetUniformLocation(grid_shader.id, "projection")
    grid_shader_view_pos_location = gl.GetUniformLocation(grid_shader.id, "viewPos")
    grid_shader_grid_scale_location = gl.GetUniformLocation(grid_shader.id, "gridScale")

    vertices := [?]f32 {
        0.0, 0.0, 0.0,
        1.0, 0.0, 0.0,
        1.0, 0.0, 1.0,
        
        1.0, 0.0, 1.0,
        0.0, 0.0, 1.0,
        0.0, 0.0, 0.0,
    }

    gl.GenVertexArrays(1, &grid_vao)
    gl.GenBuffers(1, &grid_vbo)

    gl.BindVertexArray(grid_vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, grid_vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 3, gl.FLOAT, gl.FALSE, 3 * size_of(f32), 0)

    return true
}

cleanup_grid :: proc() {
    gl.DeleteVertexArrays(1, &grid_vao)
    gl.DeleteBuffers(1, &grid_vbo)
    free_shader(grid_shader)
}

grid_pos : vec3 = {0.0, 0.0, 0.0}
grid_scale : vec3 = {32.0, 1.0, 32.0}

draw_grid :: proc() {
    grid_pos = {cam_pos.x - grid_scale.x * 0.5, 0, cam_pos.z  - grid_scale.z * 0.5}
    model : matrix[4,4]f32 = create_model_matrix(grid_pos,grid_scale)
    
    gl.Enable(gl.BLEND)
    gl.BlendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA)
    gl.UseProgram(grid_shader.id)
    gl.UniformMatrix4fv(grid_shader_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(grid_shader_view_location, 1, false, &cam_view[0][0])
    gl.UniformMatrix4fv(grid_shader_projection_location, 1, false, &cam_projection[0][0])
    gl.Uniform3f(grid_shader_view_pos_location, cam_pos.x, cam_pos.y, cam_pos.z)
    gl.Uniform1f(grid_shader_grid_scale_location, 1.0)
    gl.BindVertexArray(grid_vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
    gl.Disable(gl.BLEND)
}

//todo: move to math or so 
create_model_matrix :: proc (pos : vec3, scale : vec3) -> matrix[4,4]f32 {
    model_matrix := linalg.matrix4_translate_f32(Vec3(pos))
    model_matrix *= linalg.matrix4_scale_f32(Vec3(scale))
    // model_matrix := matrix[4,4]f32 {
    //     scale.x,       0.0,            0.0,       0.0,
    //     0.0,           scale.y,        0.0,       0.0,
    //     0.0,           0.0,            scale.z,   0.0,
    //     pos.x,         pos.y,          pos.z,     1.0,
    // }

    return model_matrix
}