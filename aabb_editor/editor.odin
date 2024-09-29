package aabb_editor

import "core:fmt"
import "vendor:glfw"
import imgui "../third-party/odin-imgui"
import "../third-party/odin-imgui/imgui_impl_glfw"
import "../third-party/odin-imgui/imgui_impl_opengl3"
import "core:math/linalg"
import "core:math"
import "core:strings"

editor_state :: struct {
    is_editor_visible : bool,
    is_editor_settings_window_visible : bool,
    io : ^imgui.IO,
    box1_pos, box1_scale, box1_color : vec3,
    was_mouse_down : bool,
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

init_imgui :: proc(state : ^app_state) -> bool {
    imgui.CHECKVERSION()
    imgui.CreateContext()
    state.editor.io = imgui.GetIO()
    state.editor.io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
    
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

process_editor_input :: proc (state: ^app_state) {
    if glfw.GetMouseButton(glfw_window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS {
        if !state.editor.was_mouse_down {
            state.editor.was_mouse_down = true
            if !state.editor.io.WantCaptureMouse {                
                ray := get_ray_from_mouse_pos(state)
                aabb := aabb { 
                    min = state.box_cursor.min,
                    max = state.box_cursor.max,
                }                

                result, is_hit := ray_aabb_intersection(ray, aabb)
                if is_hit do start_box_cursor_grabbing(ray, result, state)
            }
        } else if !state.editor.io.WantCaptureMouse {
            update_box_cursor_grabbing(state)
        }
    } else if state.editor.was_mouse_down {
        state.editor.was_mouse_down = false

        finish_box_cursor_grabbing(state)
    }

    cam_move_speed : f32 = 2.0
    cam_velocity : vec3 = {0,0,0}

    if glfw.GetKey(glfw_window, glfw.KEY_W) == glfw.PRESS do cam_velocity.z -= cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_S) == glfw.PRESS do cam_velocity.z += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_D) == glfw.PRESS do cam_velocity.x += cam_move_speed 
    if glfw.GetKey(glfw_window, glfw.KEY_A) == glfw.PRESS do cam_velocity.x -= cam_move_speed 
    
    // if glfw.GetMouseButton(glfw_window, glfw.MOUSE_BUTTON_RIGHT) == glfw.PRESS {
    if glfw.GetKey(glfw_window, glfw.KEY_Q) == glfw.PRESS do state.camera.forward = {-1,0,0}


    state.camera.pos += cam_velocity * cam_move_speed * delta_time
}

//2d-------------------------------------------------------------------------------------------------------------------
draw_editor_main_menu :: proc (state : ^app_state) {
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
            if imgui.MenuItem("Settings") do state.editor.is_editor_settings_window_visible = !state.editor.is_editor_settings_window_visible
            imgui.EndMenu()
        }

        imgui.EndMainMenuBar()
    }
}

draw_editor_settings_window :: proc (state : ^app_state) {
    if !state.editor.is_editor_settings_window_visible do return
    
    flags : imgui.WindowFlags : {.NoMove, .NoResize, .NoCollapse, .NoTitleBar}

    display_size := state.editor.io.DisplaySize
    frame_height := imgui.GetFrameHeight()
    window_pos := imgui.Vec2 {display_size.x * 0.75, frame_height}
    window_size := imgui.Vec2 {display_size.x * 0.25, display_size.y - frame_height}

    imgui.SetNextWindowPos(window_pos)
    imgui.SetNextWindowSize(window_size)
    
    if imgui.Begin("Settings", nil, flags) {
        if imgui.TreeNode("Camera") {

            imgui.SeparatorText("Position")
            imgui.DragFloat("Camera.Pos.X", &state.camera.pos.x)
            imgui.DragFloat("Camera.Pos.Y", &state.camera.pos.y)
            imgui.DragFloat("Camera.Pos.Z", &state.camera.pos.z)
            
            imgui.SeparatorText("Misc")
            imgui.DragFloat("FOV", &state.camera.fov)

            imgui.TreePop()
        }
        
        if imgui.TreeNode("Grid") {
            imgui.SeparatorText("Position")
            imgui.DragFloat("Grid.Pos.X", &state.grid.pos.x)
            imgui.DragFloat("Grid.Pos.Y", &state.grid.pos.y)
            imgui.DragFloat("Grid.Pos.Z", &state.grid.pos.z)

            imgui.SeparatorText("Scale")
            imgui.DragFloat("Grid.Scale.X", &state.grid.scale.x)
            imgui.DragFloat("Grid.Scale.Y", &state.grid.scale.y)
            imgui.DragFloat("Grid.Scale.Z", &state.grid.scale.z)
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("Box") {
            imgui.SeparatorText("Position")
            imgui.DragFloat("Box_Pos.X", &state.editor.box1_pos.x)
            imgui.DragFloat("Box_Pos.Y", &state.editor.box1_pos.y)
            imgui.DragFloat("Box_Pos.Z", &state.editor.box1_pos.z)

            imgui.SeparatorText("Scale")
            imgui.DragFloat("Box_Scale.X", &state.editor.box1_scale.x)
            imgui.DragFloat("Box_Scale.Y", &state.editor.box1_scale.y)
            imgui.DragFloat("Box_Scale.Z", &state.editor.box1_scale.z)

            imgui.SeparatorText("Misc")
            imgui.ColorEdit3("Box_Color", &state.editor.box1_color)
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("BoxCursor") {
            imgui.SeparatorText("Min")
            imgui.DragFloat("BoxCursor.Min.X", &state.box_cursor.min.x)
            imgui.DragFloat("BoxCursor.Min.Y", &state.box_cursor.min.y)
            imgui.DragFloat("BoxCursor.Min.Z", &state.box_cursor.min.z)

            imgui.SeparatorText("Max")
            imgui.DragFloat("BoxCursor.Max.X", &state.box_cursor.max.x)
            imgui.DragFloat("BoxCursor.Max.Y", &state.box_cursor.max.y)
            imgui.DragFloat("BoxCursor.Max.Z", &state.box_cursor.max.z)
            
            imgui.SeparatorText("Grab Mode")

            if imgui.Button("MOVE") do state.box_cursor.grab_mode = .MOVE
            imgui.SameLine()
            if imgui.Button("FACE_SELECT") do state.box_cursor.grab_mode = .FACE_SELECT
            imgui.SameLine()
            if imgui.Button("FACE_EDIT") {
                //todo; check if current face edit needs to be stopped
                state.box_cursor.grab_mode = .FACE_EDIT
            }
            imgui.TreePop()
        }
    }
    imgui.End()
}

draw_editor_ui :: proc (state : ^app_state) {
    if !state.editor.is_editor_visible do return
    
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
    
    // imgui.ShowDemoWindow()
    draw_editor_main_menu(state)
    draw_editor_settings_window(state)
    
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