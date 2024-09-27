package aabb_editor

import "core:fmt"
import "vendor:glfw"
import imgui "../third-party/odin-imgui"
import "../third-party/odin-imgui/imgui_impl_glfw"
import "../third-party/odin-imgui/imgui_impl_opengl3"

is_editor_visible : bool = true
is_editor_settings_window_visible : bool = true
io : ^imgui.IO = nil

init_imgui :: proc() -> bool {
    imgui.CHECKVERSION()
    imgui.CreateContext()
    io = imgui.GetIO()
    io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
    
    //Docking only
    // io.ConfigFlags += { .DockingEnable}
    // io.ConfigFlags += { .ViewportsEnable}
    // style := imgui.GetStyle()
    // style.WindowRounding = 0
    // style.Colors[imgui.Col.WindowBg].w = 1
    //

    imgui.StyleColorsDark()

    if !imgui_impl_glfw.InitForOpenGL(glfw_window, true) do return false
    if ! imgui_impl_opengl3.Init("#version 150") do return false

    return true
}

cleanup_imgui :: proc() {
    imgui_impl_opengl3.Shutdown()
    imgui_impl_glfw.Shutdown()
    imgui.DestroyContext()
}

process_editor_input :: proc () {
    if glfw.GetMouseButton(glfw_window, 0) == glfw.PRESS {
        if !io.WantCaptureMouse {
            mouse_x, mouse_y := glfw.GetCursorPos(glfw_window)
            fmt.printfln("Mouse Button pressed: X:%f, Y:%f", mouse_x, mouse_y)
        }
    }
}

draw_editor_main_menu :: proc () {
    if imgui.BeginMainMenuBar() {
        if imgui.BeginMenu("File") {
            if imgui.MenuItem("New") {
                fmt.println("New!")
            }
            if imgui.MenuItem("Open") {
                fmt.println("Open!")
            }
            if imgui.MenuItem("Save") {
                fmt.println("Save!")
            }
            imgui.Separator()
            if imgui.MenuItem("Close") do glfw.SetWindowShouldClose(glfw_window, true)

            imgui.EndMenu()
        }

        if imgui.BeginMenu("Edit") {
            if imgui.MenuItem("Settings") do is_editor_settings_window_visible = !is_editor_settings_window_visible
            imgui.EndMenu()
        }

        imgui.EndMainMenuBar()
    }
}

draw_editor_settings_window :: proc () {
    if !is_editor_settings_window_visible do return
    
    // flags : imgui.WindowFlags : {.NoMove, .NoResize, .NoCollapse}

    // display_size := io.DisplaySize
    // window_pos := imgui.Vec2 {display_size.x * 0.75, 0.0}
    // window_size := imgui.Vec2 {display_size.x * 0.25, display_size.y}

    // imgui.SetNextWindowPos(window_pos)
    // imgui.SetNextWindowSize(window_size)
    
    // if imgui.Begin("Settings", nil, flags) {
    // }
    // imgui.End()
}

draw_editor :: proc () {
    if !is_editor_visible do return
    
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
    
    // imgui.ShowDemoWindow()
    draw_editor_main_menu()
    draw_editor_settings_window()
    
    if imgui.Begin("Window containing a quit button") {
        if imgui.Button("The quit button in question") {
            glfw.SetWindowShouldClose(glfw_window, true)
        }
    }
    imgui.End()
    
    imgui.Render()
    imgui_impl_opengl3.RenderDrawData(imgui.GetDrawData())
    
    //Docking only
    // backup_current_window := glfw.GetCurrentContext()
    // imgui.UpdatePlatformWindows()
    // imgui.RenderPlatformWindowsDefault()
    // glfw.MakeContextCurrent(backup_current_window)
    //
}