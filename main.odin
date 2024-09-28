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
    
    camera := aabb_editor.make_default_cam()
    editor_state := aabb_editor.make_editor_state()
    grid_state := aabb_editor.make_grid_state()
    global_shader_state := aabb_editor.make_global_shader_state()
    box_line_renderer := aabb_editor.make_box_line_renderer_state()
    line_renderer_state := aabb_editor.make_line_renderer_state()

    if !aabb_editor.init_glfw() do return
    defer glfw.Terminate()
    
    if !aabb_editor.init_glfw_window(1280, 768, "AABB Level Editor") do return
    defer glfw.DestroyWindow(aabb_editor.glfw_window)
    
    if !aabb_editor.init_imgui(&editor_state) do return
    defer aabb_editor.cleanup_imgui()

    texture, texture_success := aabb_editor.load_texture("rabbyte_logo_512.png")
    if !texture_success do return
    defer aabb_editor.free_texture(texture)

    shader, shader_success := aabb_editor.load_shader_from_files("shaders/simple.vert.glsl", "shaders/simple.frag.glsl")
    if !shader_success do return
    defer aabb_editor.free_shader(shader)
    
    if !aabb_editor.init_global_shaders(&global_shader_state) do return
    defer aabb_editor.free_global_shaders(&global_shader_state)

    if !aabb_editor.init_grid(&grid_state) do return
    defer aabb_editor.cleanup_grid(&grid_state)

    aabb_editor.init_box_line_renderer(&box_line_renderer) 
    defer aabb_editor.cleanup_box_line_renderer(&box_line_renderer)

    aabb_editor.init_line_renderer(&line_renderer_state) 
    defer aabb_editor.cleanup_line_renderer(&line_renderer_state)
    
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
        
        aabb_editor.update_camera_matrices(&camera)
        
        aabb_editor.process_editor_input(&editor_state, &camera, &line_renderer_state)
    
        //Draw 3d
        // {   
        //     OpenGL.UseProgram(shader.id)
        //     OpenGL.ActiveTexture(OpenGL.TEXTURE0)
        //     OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
        //     OpenGL.Uniform1i(shader_texture_location, 0)
            
        //     OpenGL.BindVertexArray(vao)
        //     OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 6)
        // }
        aabb_editor.draw_grid(&grid_state, &editor_state, &camera)
        aabb_editor.draw_box_line_renderer(editor_state.box1_pos, editor_state.box1_scale, editor_state.box1_color, &box_line_renderer, &camera, &global_shader_state)
        aabb_editor.draw_line_renderer(&line_renderer_state, &camera, &global_shader_state)

        aabb_editor.draw_editor(&editor_state, &grid_state, &camera)

        glfw.SwapBuffers(aabb_editor.glfw_window)
    }
}