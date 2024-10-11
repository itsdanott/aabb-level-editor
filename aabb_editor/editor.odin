package aabb_editor

import "core:fmt"
import "core:math/linalg"
import "core:strings"
import "vendor:glfw"
import "core:strconv"
import imgui "../third-party/odin-imgui"

USE_IMGUI_MULTIWINDOW :: #config(USE_IMGUI_MULTIWINDOW, false)
HALF_PI : f32 : linalg.PI * 0.5

editor_state :: struct {
    is_editor_visible : bool,
    show_settings_window : bool,
    io : ^imgui.IO,
    //todo: instead of caching the input_btn_states all over the place - add a specific input_mapping struct for that 
    left_mouse, right_mouse, input_cam_orbit, input_cam_back, input_cam_forward, input_cam_right, input_cam_left, input_cam_up,
    input_cam_down, input_cam_yaw_right, input_cam_yaw_left : ^input_btn_state,
    mouse_pos, last_mouse_pos, mouse_delta, mouse_delta_normalized : vec2,
    snap_factor : f32,
}

make_editor_state :: proc() -> editor_state {
    return {
        is_editor_visible = true,
        show_settings_window = true,
        io = nil,
        snap_factor = 1.0,
    }
}

init_editor :: proc (state : ^app_state) -> bool {
    state.editor.left_mouse = listen_for_input_mouse_btn(glfw.MOUSE_BUTTON_LEFT, state)
    state.editor.right_mouse = listen_for_input_mouse_btn(glfw.MOUSE_BUTTON_RIGHT, state)

    state.editor.input_cam_orbit = listen_for_input_key(glfw.KEY_LEFT_ALT, state)

    state.editor.input_cam_forward = listen_for_input_key(glfw.KEY_W, state)
    state.editor.input_cam_back = listen_for_input_key(glfw.KEY_S, state)
    state.editor.input_cam_left = listen_for_input_key(glfw.KEY_A, state)
    state.editor.input_cam_right = listen_for_input_key(glfw.KEY_D, state)

    state.editor.input_cam_up = listen_for_input_key(glfw.KEY_E, state)
    state.editor.input_cam_down = listen_for_input_key(glfw.KEY_Q, state)

    state.editor.input_cam_yaw_right = listen_for_input_key(glfw.KEY_RIGHT, state)
    state.editor.input_cam_yaw_left = listen_for_input_key(glfw.KEY_LEFT, state)
    return true
}

@(private="file")
update_mouse_pos :: proc (state : ^app_state) {
    mouse_x64, mouse_y64 := glfw.GetCursorPos(glfw_window)
    when ODIN_OS == .Darwin {
        x_scale, y_scale := glfw.GetWindowContentScale(glfw_window)
        mouse_x64 *= f64(x_scale)
        mouse_y64 *= f64(y_scale)
    }
    new_mouse_pos := vec2 {f32(mouse_x64), f32(mouse_y64)}
    state.editor.mouse_pos = new_mouse_pos
    state.editor.mouse_delta = state.editor.last_mouse_pos - new_mouse_pos
    state.editor.mouse_delta = linalg.vector_normalize(state.editor.mouse_delta)
    state.editor.last_mouse_pos = state.editor.mouse_pos
}

process_editor_input :: proc (state: ^app_state) {
    update_mouse_pos(state)

    //TODO: improve the ux here, current camera orbit with alt press in combination with mouse grabbing introduces teleport issues!
    imgui_hover := state.editor.io.WantCaptureMouse
    if state.editor.left_mouse.is_start_press {
        if !imgui_hover do start_box_cursor_mouse_click(state)
    } else if state.editor.left_mouse.is_pressed{
        if !imgui_hover do update_box_cursor_grabbing(state)
    } else do finish_box_cursor_grabbing(state)
 
    if state.editor.input_cam_orbit.is_pressed && !state.editor.left_mouse.is_pressed {
        camera_mouse_orbit(state)
        return 
    }

    if imgui_hover do return

    if state.editor.right_mouse.is_pressed do camera_mouse_rotate_pitch_and_yaw(state)

    cam_velocity : vec3 = {0,0,0}

    cam_forward := state.camera.forward
    cam_right := state.camera.right
    cam_up := state.camera.up

    //keyboard cam movement input
    if state.editor.input_cam_forward.is_pressed    do cam_velocity += cam_forward 
    if state.editor.input_cam_back.is_pressed       do cam_velocity -= cam_forward 
    if state.editor.input_cam_left.is_pressed       do cam_velocity -= cam_right 
    if state.editor.input_cam_right.is_pressed      do cam_velocity += cam_right 
    
    if state.editor.input_cam_down.is_pressed       do cam_velocity -= cam_up
    if state.editor.input_cam_up.is_pressed         do cam_velocity += cam_up
    
    //keyboard cam rotation input
    if state.editor.input_cam_yaw_right.is_pressed  do state.camera.rot = state.camera.rot * 
    linalg.quaternion_angle_axis_f32(linalg.to_radians(state.camera.rot_key_sensitivity * delta_time), {0,1,0})
    if state.editor.input_cam_yaw_left.is_pressed   do state.camera.rot = state.camera.rot *
    linalg.quaternion_angle_axis_f32(linalg.to_radians(-state.camera.rot_key_sensitivity * delta_time), {0,1,0})
    
    if(linalg.vector_length(cam_velocity) > 0.2){
        cam_velocity = linalg.vector_normalize(cam_velocity)
        state.camera.pos += cam_velocity * state.camera.move_speed * delta_time
    }
}

//2d--------------------------------------------------------------------------------------------------------------------
draw_editor_ui :: proc (state : ^app_state) {
    if !state.editor.is_editor_visible do return
    
    imgui_new_frame()
    
    // imgui.ShowDemoWindow()
    draw_editor_main_menu(state)
    draw_editor_settings_window(state)
    
    imgui_render()
    
    // Docking only
    when USE_IMGUI_MULTIWINDOW {
        backup_current_window := glfw.GetCurrentContext()
        imgui.UpdatePlatformWindows()
        imgui.RenderPlatformWindowsDefault()
        glfw.MakeContextCurrent(backup_current_window)
    }
}

@(private="file")
draw_editor_main_menu :: proc (state : ^app_state) {
    if imgui.BeginMainMenuBar() {        
        if imgui.BeginMenu("File") {
            if imgui.MenuItem("New") do fmt.println("New!")
            if imgui.MenuItem("Open") do fmt.println("Open!")
            if imgui.MenuItem("Save") do fmt.println("Save!")
            imgui.Separator()
            if imgui.MenuItem("Close") do glfw.SetWindowShouldClose(glfw_window, true)
            imgui.EndMenu()
        }
        if imgui.BeginMenu("Edit") {
            if imgui.MenuItem("Settings") do state.editor.show_settings_window = !state.editor.show_settings_window
            imgui.EndMenu()
        }
        imgui.EndMainMenuBar()
    }
}

@(private="file")
draw_editor_settings_window :: proc (state : ^app_state) {
    if !state.editor.show_settings_window do return
    
    flags : imgui.WindowFlags : {.NoTitleBar}
    
    if imgui.Begin("Settings", nil, flags) {
        if imgui.TreeNode("Snapping") {
            if imgui.DragFloat("snap_factor", &state.editor.snap_factor, 1.0/8.0, 1.0/8.0, 100.0) {
                state.grid.cell_size = state.editor.snap_factor
            }
            imgui.TreePop()
        }
        if imgui.TreeNode("Camera") {
            imgui.SeparatorText("Transform")
            imgui.DragFloat3("Camera.Pos", &state.camera.pos)

            imgui.SeparatorText("Input")
            imgui.DragFloat("move_speed", &state.camera.move_speed)
            imgui.DragFloat("pos_lerp_speed", &state.camera.pos_lerp_speed)
            imgui.DragFloat("rot_lerp_speed", &state.camera.rot_lerp_speed)
            imgui.DragFloat("rot_key_sensitivity", &state.camera.rot_key_sensitivity)
            imgui.DragFloat("rot_mouse_sensitivity_x", &state.camera.rot_mouse_sensitivity_x)
            imgui.DragFloat("rot_mouse_sensitivity_y", &state.camera.rot_mouse_sensitivity_y)
            imgui.DragFloat("orbit_sensitivity", &state.camera.orbit_sensitivity)
            
            imgui.SeparatorText("Misc")
            imgui.DragFloat("Camera.FOV", &state.camera.fov)
            imgui.ColorEdit3("Camera.ClearColor", &state.camera.clear_color)

            imgui.TreePop()
        }
        
        if imgui.TreeNode("Grid") {
            if imgui.DragFloat("Grid.CellSize", &state.grid.cell_size, 1.0/8.0, 1.0/8.0, 100.0) {
                state.editor.snap_factor = state.grid.cell_size
            }
            imgui.SeparatorText("Transform")
            imgui.DragFloat3("Grid.Pos", &state.grid.pos)
            imgui.DragFloat3("Grid.Scale", &state.grid.scale)

            imgui.SeparatorText("Misc")
            imgui.SliderFloat("Grid.Alpha", &state.grid.grid_alpha, 0.0, 1.0)
            imgui.SliderFloat("Grid.FadeDist", &state.grid.grid_fade_dist, 2.0, 100.0)
            imgui.ColorEdit3("Grid.Checker.Col1", &state.grid.checker_col1)
            imgui.ColorEdit3("Grid.Checker.Col2", &state.grid.checker_col2)
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("BoxCursor") {
            imgui.SeparatorText("Min")
            imgui.DragFloat3("BoxCursor.Min", &state.box_cursor.min)

            imgui.SeparatorText("Max")
            imgui.DragFloat3("BoxCursor.Max", &state.box_cursor.max)

            imgui.SeparatorText("Size")
            size := aabb_get_size({state.box_cursor.min, state.box_cursor.max})
            if imgui.DragFloat3("BoxCursor.Size", &size) do state.box_cursor.max = state.box_cursor.min + size
            
            if imgui.Button("Fix Min Max") {
                box_cursor_aabb := aabb {state.box_cursor.min, state.box_cursor.max}
                aabb_fix_min_max(&box_cursor_aabb)
                state.box_cursor.min = box_cursor_aabb.min
                state.box_cursor.max = box_cursor_aabb.max
            }

            imgui.SeparatorText("Misc")
            imgui.ColorEdit3("Cursor.Color.Default", &state.box_cursor.color_default)
            imgui.ColorEdit3("Cursor.Color.Selected", &state.box_cursor.color_selected)
            
            imgui.SeparatorText("Mouse Mode")
            if imgui.Button("MOVE") do state.box_cursor.mouse_mode = .MOVE
            imgui.SameLine()
            if imgui.Button("BRUSH SELECT") do state.box_cursor.mouse_mode = .BRUSH_SELECT
            imgui.SameLine()
            if imgui.Button("FACE_SELECT") do state.box_cursor.mouse_mode = .FACE_SELECT
            imgui.SameLine()
            if imgui.Button("FACE_EDIT") {
                //todo: check if current face edit needs to be stopped
                state.box_cursor.mouse_mode = .FACE_EDIT
            }

            imgui.SeparatorText("Submit")
            if imgui.Button("Create Brush") {
                create_brush_from_box_cursor(state)
            }
            
            imgui.TreePop()
        }
        
        if imgui.TreeNode("Textures") {
            if imgui.Button("Generate Texture Array") do generate_texture_array(state)
            
            for texture, index in state.textures {
                imgui.Text("[%zu] %dx%d (%hu channels)", texture.id, texture.width, texture.height, texture.channels)
                imgui.Image(imgui.TextureID(uintptr(texture.id)), {128, 128})

                if texture.is_in_array && texture.array_index > -1 {
                    if state.selected_brush != nil {                        
                        imgui.SeparatorText("Assign Texture")
                        btn_label_all := fmt.aprintf("To all Brush faces ##%v", index)
                        if imgui.Button(strings.clone_to_cstring(btn_label_all)) {
                            fmt.printfln("Assigning texture array index %v to brush!", texture.array_index)
                            assign_texture_to_brush(state.selected_brush, texture.array_index)
                        }

                        if state.box_cursor.mouse_mode == .FACE_SELECT {
                            btn_label_selected := fmt.aprintf("Selected Brush Face ##%v", index)
                            if imgui.Button(strings.clone_to_cstring(btn_label_selected)) {
                                fmt.printfln("Assigning texture array index %v to brush face-index:", 
                                    texture.array_index, state.box_cursor.selected_face_index)
                                assign_texture_to_brush_face(state.selected_brush, texture.array_index, 
                                    state.box_cursor.selected_face_index)
                            }
                        }
                    }
                    imgui.Separator()
                    imgui.Text("Array-Index: %d", texture.array_index)
                }

                checkbox_label := fmt.aprintf("in_array##%v", index)
                imgui.Checkbox(strings.clone_to_cstring(checkbox_label), &state.textures[index].is_in_array)
                imgui.Separator()
            }

            imgui.TreePop()
        }
    }
    imgui.End()

    is_brush_selected := state.selected_brush != nil
    if imgui.Begin("Brushes", nil) {
        if imgui.TreeNode("List") {
            for brush in state.brushes {
                label := fmt.aprintf("Brush%v", brush.id)
                cstr :=  strings.clone_to_cstring(label)
                defer delete(label)

                if imgui.Selectable(cstr, is_brush_selected && state.selected_brush.id == brush.id) {
                    select_brush(brush, state) 
                }
            }
            imgui.TreePop()
        }
    }
    imgui.End()
}