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
    defer aabb_editor.cleanup_input(&app_state)

    if !aabb_editor.init_glfw() do return
    defer glfw.Terminate()
    
    if !aabb_editor.init_glfw_window(1280, 768, "AABB Level Editor") do return
    defer glfw.DestroyWindow(aabb_editor.glfw_window)
    
    if !aabb_editor.init_imgui(&app_state) do return
    defer aabb_editor.cleanup_imgui()

    if !aabb_editor.init_editor(&app_state) do return
    
    defer aabb_editor.cleanup_textures(&app_state)
    
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

    for !glfw.WindowShouldClose(aabb_editor.glfw_window) {
        //begin frame
        OpenGL.ClearColor(app_state.camera.clear_color.r, app_state.camera.clear_color.g, app_state.camera.clear_color.b, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT | OpenGL.DEPTH_BUFFER_BIT)

        //update
        glfw.PollEvents()  
        aabb_editor.glfw_process_callbacks(&app_state)        
        aabb_editor.update_camera_matrices(&app_state.camera)        
        aabb_editor.process_editor_input(&app_state)

        //draw 3d
        aabb_editor.draw_grid(&app_state)
        aabb_editor.draw_brushes(&app_state)
        aabb_editor.draw_line_renderer(&app_state)

        aabb_editor.draw_box_cursor(&app_state)

        //draw 2d
        aabb_editor.draw_editor_ui(&app_state)

        //end of frame
        glfw.SwapBuffers(aabb_editor.glfw_window)
        aabb_editor.glfw_scroll = {0,0}
    }
}