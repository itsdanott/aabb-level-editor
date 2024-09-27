package aabb_editor

import "core:fmt"
import "vendor:glfw"
import imgui "../third-party/odin-imgui"
import "../third-party/odin-imgui/imgui_impl_glfw"
import "../third-party/odin-imgui/imgui_impl_opengl3"

is_editor_visible : bool = true
is_editor_settings_window_visible : bool = true
io : ^imgui.IO = nil

box1_pos, box1_scale, box1_color : vec3 = {0,0,0}, {1,1,1}, {0.5,1,0.5}

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

    delta_time : f32 : 1.0 / 60.0
    cam_move_speed : f32 = 2.0
    cam_velocity : vec3 = {0,0,0}

    if glfw.GetKey(glfw_window, glfw.KEY_W) == glfw.PRESS do cam_velocity.z -= cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_S) == glfw.PRESS do cam_velocity.z += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_D) == glfw.PRESS do cam_velocity.x += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_A) == glfw.PRESS do cam_velocity.x -= cam_move_speed 

    new_cam_pos := Vec3(cam_pos) + Vec3(cam_velocity) * cam_move_speed * delta_time
    cam_pos = {new_cam_pos.x, new_cam_pos.y, new_cam_pos.z}
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
    
    flags : imgui.WindowFlags : {.NoMove, .NoResize, .NoCollapse, .NoTitleBar}

    display_size := io.DisplaySize
    frame_height := imgui.GetFrameHeight()
    window_pos := imgui.Vec2 {display_size.x * 0.75, frame_height}
    window_size := imgui.Vec2 {display_size.x * 0.25, display_size.y - frame_height}

    imgui.SetNextWindowPos(window_pos)
    imgui.SetNextWindowSize(window_size)
    
    if imgui.Begin("Settings", nil, flags) {
        if imgui.TreeNode("Camera") {

            imgui.DragFloat("FOV", &cam_fov)
            imgui.DragFloat("Camera.X", &cam_pos.x)
            imgui.DragFloat("Camera.Y", &cam_pos.y)
            imgui.DragFloat("Camera.Z", &cam_pos.z)

            imgui.TreePop()
        }
        
        if imgui.TreeNode("Grid") {
            imgui.DragFloat("Grid_Pos.X", &grid_pos.x)
            imgui.DragFloat("Grid_Pos.Y", &grid_pos.y)
            imgui.DragFloat("Grid_Pos.Z", &grid_pos.z)

            imgui.DragFloat("Grid_Scale.X", &grid_scale.x)
            imgui.DragFloat("Grid_Scale.Y", &grid_scale.y)
            imgui.DragFloat("Grid_Scale.Z", &grid_scale.z)
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("Box") {
            imgui.DragFloat("Box_Pos.X", &box1_pos.x)
            imgui.DragFloat("Box_Pos.Y", &box1_pos.y)
            imgui.DragFloat("Box_Pos.Z", &box1_pos.z)

            imgui.DragFloat("Box_Scale.X", &box1_scale.x)
            imgui.DragFloat("Box_Scale.Y", &box1_scale.y)
            imgui.DragFloat("Box_Scale.Z", &box1_scale.z)

            box_col := Vec3(box1_color)
            imgui.ColorEdit3("Box_Color", &box_col)
            box1_color = {box_col.r, box_col.g, box_col.b}
            
            imgui.TreePop()
        }
    }
    imgui.End()
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