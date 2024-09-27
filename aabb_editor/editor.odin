package aabb_editor

import "core:fmt"
import "vendor:glfw"
import imgui "../third-party/odin-imgui"
import "../third-party/odin-imgui/imgui_impl_glfw"
import "../third-party/odin-imgui/imgui_impl_opengl3"

editor_state :: struct {
    is_editor_visible : bool,
    is_editor_settings_window_visible : bool,
    io : ^imgui.IO,
    box1_pos, box1_scale, box1_color : vec3,
}

make_editor_state :: proc() -> editor_state {
    return {
        is_editor_visible = true,
        is_editor_settings_window_visible = true,
        io = nil,
        box1_pos = {0,0,0},  
        box1_scale = {1,1,1},
        box1_color = {0.5,1,0.5},
    }
}

init_imgui :: proc(state : ^editor_state) -> bool {
    imgui.CHECKVERSION()
    imgui.CreateContext()
    state.io = imgui.GetIO()
    state.io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
    
    //Docking only
    // state.io.ConfigFlags += { .DockingEnable}
    // state.io.ConfigFlags += { .ViewportsEnable}
    // style := imgui.GetStyle()
    // style.WindowRounding = 0
    // style.Colors[imgui.Col.WindowBg].w = 1
    //

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

process_editor_input :: proc (state: ^editor_state, cam: ^camera) {
    if glfw.GetMouseButton(glfw_window, 0) == glfw.PRESS {
        if !state.io.WantCaptureMouse {
            mouse_x, mouse_y := glfw.GetCursorPos(glfw_window)
            fmt.printfln("Mouse Button pressed: X:%f, Y:%f", mouse_x, mouse_y)
        }
    }

    delta_time : f32 : 1.0 / 60.0
    cam_move_speed : f32 = 2.0
    cam_velocity : vec3 = {0,0,0}

    if glfw.GetKey(glfw_window, glfw.KEY_W) == glfw.PRESS do cam_velocity.z -= cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_S) == glfw.PRESS do cam_velocity.z += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_D) == glfw.PRESS do cam_velocity.x += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_A) == glfw.PRESS do cam_velocity.x -= cam_move_speed 

    cam.pos += cam_velocity * cam_move_speed * delta_time
}

draw_editor_main_menu :: proc (state : ^editor_state) {
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
            if imgui.MenuItem("Settings") do state.is_editor_settings_window_visible = !state.is_editor_settings_window_visible
            imgui.EndMenu()
        }

        imgui.EndMainMenuBar()
    }
}

draw_editor_settings_window :: proc (state : ^editor_state, grid : ^grid_state, cam : ^camera) {
    if !state.is_editor_settings_window_visible do return
    
    flags : imgui.WindowFlags : {.NoMove, .NoResize, .NoCollapse, .NoTitleBar}

    display_size := state.io.DisplaySize
    frame_height := imgui.GetFrameHeight()
    window_pos := imgui.Vec2 {display_size.x * 0.75, frame_height}
    window_size := imgui.Vec2 {display_size.x * 0.25, display_size.y - frame_height}

    imgui.SetNextWindowPos(window_pos)
    imgui.SetNextWindowSize(window_size)
    
    if imgui.Begin("Settings", nil, flags) {
        if imgui.TreeNode("Camera") {

            imgui.SeparatorText("Position")
            imgui.DragFloat("Camera.Pos.X", &cam.pos.x)
            imgui.DragFloat("Camera.Pos.Y", &cam.pos.y)
            imgui.DragFloat("Camera.Pos.Z", &cam.pos.z)
            
            imgui.SeparatorText("Misc")
            imgui.DragFloat("FOV", &cam.fov)

            imgui.TreePop()
        }
        
        if imgui.TreeNode("Grid") {
            imgui.SeparatorText("Position")
            imgui.DragFloat("Grid.Pos.X", &grid.pos.x)
            imgui.DragFloat("Grid.Pos.Y", &grid.pos.y)
            imgui.DragFloat("Grid.Pos.Z", &grid.pos.z)

            imgui.SeparatorText("Scale")
            imgui.DragFloat("Grid.Scale.X", &grid.scale.x)
            imgui.DragFloat("Grid.Scale.Y", &grid.scale.y)
            imgui.DragFloat("Grid.Scale.Z", &grid.scale.z)
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("Box") {
            imgui.SeparatorText("Position")
            imgui.DragFloat("Box_Pos.X", &state.box1_pos.x)
            imgui.DragFloat("Box_Pos.Y", &state.box1_pos.y)
            imgui.DragFloat("Box_Pos.Z", &state.box1_pos.z)

            imgui.SeparatorText("Scale")
            imgui.DragFloat("Box_Scale.X", &state.box1_scale.x)
            imgui.DragFloat("Box_Scale.Y", &state.box1_scale.y)
            imgui.DragFloat("Box_Scale.Z", &state.box1_scale.z)

            imgui.SeparatorText("Misc")
            imgui.ColorEdit3("Box_Color", &state.box1_color)
            
            imgui.TreePop()
        }
    }
    imgui.End()
}

draw_editor :: proc (state : ^editor_state, grid : ^grid_state, cam : ^camera) {
    if !state.is_editor_visible do return
    
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
    
    // imgui.ShowDemoWindow()
    draw_editor_main_menu(state)
    draw_editor_settings_window(state, grid, cam)
    
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