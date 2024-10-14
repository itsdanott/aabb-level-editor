package aabb_editor
import gl "vendor:OpenGL"

viewport_renderer_state :: struct {
    vao, vbo : u32,
    shader : ^shader,
    //TODO: framebuffer
    shader_texture_location : i32,
}

@(private)
make_viewport_renderer_state :: proc() -> viewport_renderer_state {
    return {}
}

init_viewport_renderer :: proc (state : ^app_state) -> bool {
    gl.GenVertexArrays(1, &state.viewport_renderer.vao)
    gl.GenBuffers(1, &state.viewport_renderer.vbo)

    gl.BindVertexArray(state.viewport_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.viewport_renderer.vbo)

    vertices := [?]f32 {
        //Position(XY)  TexCoord(XY)
        -1.0,  -1.0,      0,      0,
         1.0,  -1.0,    1.0,      0,
         1.0,   1.0,    1.0,    1.0,

         1.0,   1.0,    1.0,    1.0,
        -1.0,   1.0,      0,    1.0,
        -1.0,  -1.0,      0,      0,
    }

    gl.BufferData(gl.ARRAY_BUFFER, size_of(f32) * len(vertices), &vertices, gl.STATIC_DRAW)

    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 0)

    gl.EnableVertexAttribArray(1)
    gl.VertexAttribPointer(1, 2, gl.FLOAT, gl.FALSE, 4 * size_of(f32), 2 * size_of(f32))

    shader, shader_success := load_shader_from_files("shaders/viewport.vert.glsl", "shaders/viewport.frag.glsl")

    if !shader_success do return false
    
    state.viewport_renderer.shader_texture_location = gl.GetUniformLocation(shader.id, "viewportTexture")
    state.viewport_renderer.shader = shader

    texture_success : bool

    //TODO: generate viewport texture (framebuffer)

    return true
}

cleanup_viewport_renderer :: proc(state : ^app_state) {
    gl.DeleteVertexArrays(1, &state.viewport_renderer.vao)
    gl.DeleteBuffers(1, &state.viewport_renderer.vao)
    free_shader(state.viewport_renderer.shader)
    //TODO: free framebuffer
}

draw_viewport :: proc(state : ^app_state) {
    gl.UseProgram(state.viewport_renderer.shader.id)
    //TODO: bind framebuffer
    gl.ActiveTexture(gl.TEXTURE1)
    gl.Uniform1i(state.viewport_renderer.shader_texture_location, 0) 
    gl.BindVertexArray(state.viewport_renderer.vao)
    gl.DrawArrays(gl.TRIANGLES, 0, 6)
}