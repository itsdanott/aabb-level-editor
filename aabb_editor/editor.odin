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
    was_mouse_down, was_alt_pressed : bool,
    mouse_pos, last_mouse_pos, mouse_delta, mouse_delta_normalized : vec2,
}

make_editor_state :: proc() -> editor_state {
    return {
        is_editor_visible = true,
        is_editor_settings_window_visible = true,
        io = nil,
    }
}

init_imgui :: proc(state : ^app_state) -> bool {
    imgui.CHECKVERSION()
    imgui.CreateContext()
    state.editor.io = imgui.GetIO()
    state.editor.io.ConfigFlags += {.NavEnableKeyboard, .NavEnableGamepad}
    
    // Docking only
    state.editor.io.ConfigFlags += { .DockingEnable}
    state.editor.io.ConfigFlags += { .ViewportsEnable}
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
@private
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
    
    alt_pressed := glfw.GetKey(glfw_window, glfw.KEY_LEFT_ALT) == glfw.PRESS
    if !alt_pressed && state.editor.was_alt_pressed do state.editor.was_alt_pressed = false
    mouse_button_left_press := glfw.GetMouseButton(glfw_window, glfw.MOUSE_BUTTON_LEFT) == glfw.PRESS
    mouse_button_right_press : = glfw.GetMouseButton(glfw_window, glfw.MOUSE_BUTTON_RIGHT) == glfw.PRESS

    if mouse_button_left_press {
        if !state.editor.was_mouse_down {
            state.editor.was_mouse_down = true
            if !state.editor.io.WantCaptureMouse {        
                start_box_cursor_mouse_click(state)    
            }
        } else if !state.editor.io.WantCaptureMouse {
            update_box_cursor_grabbing(state)
        }
    } else if state.editor.was_mouse_down {
        state.editor.was_mouse_down = false

        finish_box_cursor_grabbing(state)
    }

    cam_velocity : vec3 = {0,0,0}

    cam_forward := state.camera.forward
    cam_right := state.camera.right
    cam_up := state.camera.up

    if glfw.GetKey(glfw_window, glfw.KEY_W) == glfw.PRESS do cam_velocity += cam_forward 
    if glfw.GetKey(glfw_window, glfw.KEY_S) == glfw.PRESS do cam_velocity -= cam_forward 
    if glfw.GetKey(glfw_window, glfw.KEY_D) == glfw.PRESS do cam_velocity += cam_right 
    if glfw.GetKey(glfw_window, glfw.KEY_A) == glfw.PRESS do cam_velocity -= cam_right 
    
    if glfw.GetKey(glfw_window, glfw.KEY_Q) == glfw.PRESS do cam_velocity -= cam_up
    if glfw.GetKey(glfw_window, glfw.KEY_E) == glfw.PRESS do cam_velocity += cam_up
    
    //keyboard rotation
    if glfw.GetKey(glfw_window, glfw.KEY_RIGHT) == glfw.PRESS do state.camera.rot = state.camera.rot * linalg.quaternion_angle_axis_f32(math.to_radians(state.camera.rot_key_sensitivity * delta_time), {0,1,0})
    if glfw.GetKey(glfw_window, glfw.KEY_LEFT) == glfw.PRESS do state.camera.rot = state.camera.rot * linalg.quaternion_angle_axis_f32(math.to_radians(-state.camera.rot_key_sensitivity * delta_time), {0,1,0})

    if(linalg.vector_length(cam_velocity) > 0.2){
        cam_velocity = linalg.vector_normalize(cam_velocity)
        state.camera.pos += cam_velocity * state.camera.move_speed * delta_time
    }
 
    if mouse_button_right_press {
        if !alt_pressed {
            if linalg.vector_length(state.editor.mouse_delta) > 0.0001 {
                pitch_angle : f32 = state.editor.mouse_delta.y * state.camera.rot_mouse_sensitivity_y * delta_time
                yaw_angle : f32 = -state.editor.mouse_delta.x * state.camera.rot_mouse_sensitivity_x * delta_time
                
                yaw_quat : quaternion128 = linalg.quaternion_angle_axis_f32(math.to_radians(yaw_angle), vec3{0.0, 1.0, 0.0})
                pitch_quat : quaternion128 = linalg.quaternion_angle_axis_f32(math.to_radians(pitch_angle), state.camera.right)
                
                state.camera.rot = state.camera.rot * yaw_quat
                state.camera.rot = state.camera.rot * pitch_quat
                
                state.camera.rot = linalg.quaternion_normalize(state.camera.rot)
            }
        } else {
            camera_target := linalg.lerp(state.box_cursor.min, state.box_cursor.max, 0.5)
            if !state.editor.was_alt_pressed {
                state.editor.was_alt_pressed = true
                state.box_cursor.camera_distance = linalg.distance(camera_target, state.camera.pos)
                look_quat := linalg.quaternion_look_at_f32(state.camera.pos, camera_target, vec3{0.0,1.0,0.0} )
                state.box_cursor.camera_pitch = linalg.pitch_from_quaternion(look_quat)
                state.box_cursor.camera_yaw = linalg.yaw_from_quaternion(look_quat)
            } else if math.abs(glfw_scroll.y) > 0.01 do state.box_cursor.camera_distance = math.max(state.box_cursor.camera_distance + -glfw_scroll.y, 0.5)

            if math.abs(state.editor.mouse_delta.x) > 0.1 do state.box_cursor.camera_yaw += state.editor.mouse_delta.x * state.camera.orbit_sensitivity * delta_time
            if math.abs(state.editor.mouse_delta.y) > 0.1 do state.box_cursor.camera_pitch += state.editor.mouse_delta.y * state.camera.orbit_sensitivity * delta_time

            pitch := state.box_cursor.camera_pitch
            yaw := state.box_cursor.camera_yaw
            
            orbit_x := state.box_cursor.camera_distance * math.cos_f32(pitch) * math.sin_f32(yaw)
            orbit_y := state.box_cursor.camera_distance * math.sin_f32(pitch)
            orbit_z := state.box_cursor.camera_distance * math.cos_f32(pitch) * math.cos_f32(yaw)

            state.camera.pos = {orbit_x, orbit_y, orbit_z}
            state.camera.rot = linalg.quaternion_look_at_f32(state.camera.pos, camera_target, vec3{0.0,1.0,0.0} )
        }
    } 
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
    
    // Docking-Only
    flags : imgui.WindowFlags : {.NoTitleBar}
    // No-Docking Only
    // flags : imgui.WindowFlags : {.NoMove, .NoResize, .NoCollapse, .NoTitleBar}

    // display_size := state.editor.io.DisplaySize
    // frame_height := imgui.GetFrameHeight()
    // window_pos := imgui.Vec2 {display_size.x * 0.75, frame_height}
    // window_size := imgui.Vec2 {display_size.x * 0.25, display_size.y - frame_height}

    // imgui.SetNextWindowPos(window_pos)
    // imgui.SetNextWindowSize(window_size)
    
    if imgui.Begin("Settings", nil, flags) {
        if imgui.TreeNode("Camera") {

            imgui.SeparatorText("Position")
            imgui.DragFloat("Camera.Pos.X", &state.camera.pos.x)
            imgui.DragFloat("Camera.Pos.Y", &state.camera.pos.y)
            imgui.DragFloat("Camera.Pos.Z", &state.camera.pos.z)

            imgui.SeparatorText("Input")
            imgui.DragFloat("move_speed", &state.camera.move_speed)
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
            imgui.SeparatorText("Position")
            imgui.DragFloat("Grid.Pos.X", &state.grid.pos.x)
            imgui.DragFloat("Grid.Pos.Y", &state.grid.pos.y)
            imgui.DragFloat("Grid.Pos.Z", &state.grid.pos.z)

            imgui.SeparatorText("Scale")
            imgui.DragFloat("Grid.Scale.X", &state.grid.scale.x)
            imgui.DragFloat("Grid.Scale.Y", &state.grid.scale.y)
            imgui.DragFloat("Grid.Scale.Z", &state.grid.scale.z)

            imgui.SeparatorText("Misc")
            imgui.SliderFloat("Grid.Alpha", &state.grid.grid_alpha, 0.0, 1.0)
            imgui.SliderFloat("Grid.FadeDist", &state.grid.grid_fade_dist, 2.0, 100.0)
            imgui.ColorEdit3("Grid.Checker.Col1", &state.grid.checker_col1)
            imgui.ColorEdit3("Grid.Checker.Col2", &state.grid.checker_col2)
            
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

            imgui.SeparatorText("Misc")
            imgui.ColorEdit3("Cursor.Color", &state.box_cursor.color)
            
            imgui.SeparatorText("Mouse Mode")
            if imgui.Button("MOVE") do state.box_cursor.mouse_mode = .MOVE
            imgui.SameLine()
            if imgui.Button("BRUSH SELECT") do state.box_cursor.mouse_mode = .BRUSH_SELECT
            imgui.SameLine()
            if imgui.Button("FACE_SELECT") do state.box_cursor.mouse_mode = .FACE_SELECT
            imgui.SameLine()
            if imgui.Button("FACE_EDIT") {
                //todo; check if current face edit needs to be stopped
                state.box_cursor.mouse_mode = .FACE_EDIT
            }

            imgui.SeparatorText("Submit")
            if imgui.Button("Create Brush") {
                create_brush_from_box_cursor(state)
            }
            
            imgui.TreePop()
        }

        //TODO:
        // if imgui.TreeNode("Brush") {

        //     imgui.TreePop()
        // }
        
        if imgui.TreeNode("Textures") {
            if imgui.Button("Generate Texture Array") {
                generate_texture_array(state)
            }
            for texture, index in state.textures {
                imgui.Text("[%zu] %dx%d (%hu channels)", texture.id, texture.width, texture.height, texture.channels)
                imgui.Image(imgui.TextureID(uintptr(texture.id)), {128, 128})

                if texture.is_in_array && texture.array_index > -1 {
                    if state.selected_brush != nil {
                        
                        imgui.SeparatorText("Assign Texture")
                        button_label_entire := fmt.aprintf("To all Brush faces ##%v", index)
                        if imgui.Button(strings.clone_to_cstring(button_label_entire)) {
                            fmt.printfln("Assigning texture array index %v to brush!", texture.array_index)
                            assign_texture_to_brush(state.selected_brush, texture.array_index)
                        }

                        if state.box_cursor.mouse_mode == .FACE_SELECT {
                            button_label_face := fmt.aprintf("Selected Brush Face ##%v", index)
                            if imgui.Button(strings.clone_to_cstring(button_label_face)) {
                                fmt.printfln("Assigning texture array index %v to brush face-index:", texture.array_index, state.box_cursor.selected_face_index)
                                assign_texture_to_brush_face(state.selected_brush, texture.array_index, state.box_cursor.selected_face_index)
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
}

draw_editor_ui :: proc (state : ^app_state) {
    if !state.editor.is_editor_visible do return
    
    imgui_impl_opengl3.NewFrame()
    imgui_impl_glfw.NewFrame()
    imgui.NewFrame()
    
    // imgui.ShowDemoWindow()
    draw_editor_main_menu(state)
    draw_editor_settings_window(state)
    
    imgui.Render()
    imgui_impl_opengl3.RenderDrawData(imgui.GetDrawData())
    
    // Docking only
    backup_current_window := glfw.GetCurrentContext()
    imgui.UpdatePlatformWindows()
    imgui.RenderPlatformWindowsDefault()
    glfw.MakeContextCurrent(backup_current_window)
    
}