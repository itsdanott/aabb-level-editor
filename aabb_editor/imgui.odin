package aabb_editor

import imgui "../third-party/odin-imgui"
import "../third-party/odin-imgui/imgui_impl_glfw"
import "../third-party/odin-imgui/imgui_impl_opengl3"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// imgui - procs
init_imgui :: proc(state : ^app_state) -> bool {
    imgui.CHECKVERSION()
    imgui.CreateContext()
    state.editor.io = imgui.GetIO()
    state.editor.io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
    
    // Docking only
    when USE_IMGUI_MULTIWINDOW do state.editor.io.ConfigFlags += { .ViewportsEnable}
    
    state.editor.io.ConfigFlags += { .DockingEnable}
    style := imgui.GetStyle()
    style.WindowRounding = 0
    style.Colors[imgui.Col.WindowBg].w = 1
    

    imgui.StyleColorsDark()

    if !imgui_impl_glfw.InitForOpenGL(glfw_window, true) do return false
    if !imgui_impl_opengl3.Init("#version 150") do return false

    return true
}

cleanup_imgui :: proc() {
    imgui_impl_opengl3.Shutdown()
    imgui_impl_glfw.Shutdown()
    imgui.DestroyContext()
}

imgui_new_frame :: proc () {
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
}

imgui_render :: proc () {
    imgui.Render()
    imgui_impl_opengl3.RenderDrawData(imgui.GetDrawData())
}