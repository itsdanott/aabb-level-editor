package main

import "aabb_editor"
import "core:fmt"
import "vendor:glfw"
import "vendor:OpenGL"
import "core:math/linalg"

check_for_supported_platform :: proc () {
    when !(ODIN_OS == .Darwin || ODIN_OS == .Windows || ODIN_OS == .Linux) {
        fmt.panicf("Unsupported Platform: %s", ODIN_OS)
    }
}

main :: proc() {
    check_for_supported_platform()

    aabb_editor.init_base_path()

    app_state := aabb_editor.make_app_state()

    if !aabb_editor.init_glfw() do return
    defer glfw.Terminate()
    
    if !aabb_editor.init_glfw_window(1280, 768, "AABB Level Editor") do return
    defer glfw.DestroyWindow(aabb_editor.glfw_window)
    
    if !aabb_editor.init_imgui(&app_state) do return
    defer aabb_editor.cleanup_imgui()
    
    defer aabb_editor.cleanup_textures(&app_state)

    shader, shader_success := aabb_editor.load_shader_from_files("shaders/simple.vert.glsl", "shaders/simple.frag.glsl")
    if !shader_success do return
    defer aabb_editor.free_shader(shader)
    
    if !aabb_editor.init_global_shaders(&app_state) do return
    defer aabb_editor.free_global_shaders(&app_state)

    if !aabb_editor.init_grid(&app_state) do return
    defer aabb_editor.cleanup_grid(&app_state)

    aabb_editor.init_box_line_renderer(&app_state) 
    defer aabb_editor.cleanup_box_line_renderer(&app_state)

    aabb_editor.init_line_renderer(&app_state) 
    defer aabb_editor.cleanup_line_renderer(&app_state)

    aabb_editor.init_quad_renderer(&app_state)
    defer aabb_editor.cleanup_quad_renderer(&app_state)

    aabb_editor.init_brush_renderer(&app_state)
    defer aabb_editor.cleanup_brush_renderer(&app_state)
    defer aabb_editor.cleanup_brushes(&app_state)
    
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
        OpenGL.ClearColor(app_state.camera.clear_color.r, app_state.camera.clear_color.g, app_state.camera.clear_color.b, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

        glfw.PollEvents()  

        aabb_editor.glfw_process_callbacks(&app_state)
        
        aabb_editor.update_camera_matrices(&app_state.camera)
        
        aabb_editor.process_editor_input(&app_state)
    
        //Draw 3d
        // {   
        //     OpenGL.UseProgram(shader.id)
        //     OpenGL.ActiveTexture(OpenGL.TEXTURE0)
        //     OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
        //     OpenGL.Uniform1i(shader_texture_location, 0)
            
        //     OpenGL.BindVertexArray(vao)
        //     OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 6)
        // }
        aabb_editor.draw_grid(&app_state)
        aabb_editor.draw_brushes(&app_state)
        aabb_editor.draw_line_renderer(&app_state)

        aabb_editor.draw_box_cursor(&app_state)

        //2d
        aabb_editor.draw_editor_ui(&app_state)

        glfw.SwapBuffers(aabb_editor.glfw_window)
        aabb_editor.glfw_scroll = {0,0}
    }
}