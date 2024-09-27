package main

import "aabb_editor"
import "core:fmt"
import "vendor:glfw"
import "vendor:OpenGL"

check_for_supported_platform :: proc () {
    when !(ODIN_OS == .Darwin || ODIN_OS == .Windows || ODIN_OS == .Linux) {
        fmt.panicf("Unsupported Platform: %s", ODIN_OS)
    }
}

main :: proc() {
    check_for_supported_platform()
    aabb_editor.init_base_path()

    if !aabb_editor.init_glfw() do return
    defer glfw.Terminate()
    
    if !aabb_editor.init_glfw_window(800, 600, "Hellope Odin") do return
    defer glfw.DestroyWindow(aabb_editor.glfw_window)
    
    if !aabb_editor.init_imgui() do return
    defer aabb_editor.cleanup_imgui()

    texture, texture_success := aabb_editor.load_texture("rabbyte_logo_512.png")
    if !texture_success do return
    defer aabb_editor.free_texture(texture)

    shader, shader_success := aabb_editor.load_shader_from_files("shaders/simple.vert.glsl", "shaders/simple.frag.glsl")
    if !shader_success do return
    defer aabb_editor.free_shader(shader)

    unlit_color_shader, unlit_color_shader_success := aabb_editor.load_shader_from_files("shaders/unlit_color.vert.glsl", "shaders/unlit_color.frag.glsl")
    if !unlit_color_shader_success do return
    defer aabb_editor.free_shader(unlit_color_shader)

    vertices := [?]f32 {
        //Position(XY)  TexCoord(XY)
        -1.0,  -1.0,      0,      0,
         1.0,  -1.0,    1.0,      0,
         1.0,   1.0,    1.0,    1.0,

         1.0,   1.0,    1.0,    1.0,
        -1.0,   1.0,      0,    1.0,
        -1.0,  -1.0,      0,      0,
    }

    vertices_num := len(vertices)

    vao, vbo : u32

    OpenGL.GenVertexArrays(1, &vao)
    OpenGL.GenBuffers(1, &vbo)

    defer OpenGL.DeleteVertexArrays(1, &vao)
    defer OpenGL.DeleteBuffers(1, &vbo)

    OpenGL.BindVertexArray(vao)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, vbo)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(f32) * vertices_num, &vertices, OpenGL.STATIC_DRAW)

    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(0, 2, OpenGL.FLOAT, OpenGL.FALSE, 4 * size_of(f32), 0)

    OpenGL.EnableVertexAttribArray(1)
    OpenGL.VertexAttribPointer(1, 2, OpenGL.FLOAT, OpenGL.FALSE, 4 * size_of(f32), 2 * size_of(f32))

    shader_texture_location := OpenGL.GetUniformLocation(shader.id, "screenTexture")

    for !glfw.WindowShouldClose(aabb_editor.glfw_window) {
        OpenGL.ClearColor(0.25, 0.25, 0.5, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        glfw.PollEvents()        

        aabb_editor.process_editor_input()
    
        //Draw 3d
        {   
            OpenGL.UseProgram(shader.id)
            OpenGL.ActiveTexture(OpenGL.TEXTURE0)
            OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
            OpenGL.Uniform1i(shader_texture_location, 0)
            
            OpenGL.BindVertexArray(vao)
            OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 6)
        }

        aabb_editor.draw_editor()

        glfw.SwapBuffers(aabb_editor.glfw_window)
    }
}