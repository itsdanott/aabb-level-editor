package aabb_editor

import "vendor:glfw"
import "core:strings"
import "core:fmt"
import "base:runtime"
import "vendor:OpenGL"
import "core:c"
import "core:path/filepath"

GL_VERSION_MAJOR : c.int : 4
GL_VERSION_MINOR : c.int : 1
glfw_window : glfw.WindowHandle = nil

framebuffer_size_x,framebuffer_size_y : i32
framebuffer_aspect : f32
glfw_scroll : vec2

glfw_dropped_paths : [dynamic]string

//Todo: think of a solution to avoid global variables and replace with this struct
window_state :: struct {
    glfw_window : glfw.WindowHandle,
    framebuffer_size_x, framebuffer_size_y : i32,
    framebuffer_aspect : f32,
}

glfw_error :: proc "c" (error : c.int, description : cstring) {
    context = runtime.default_context()
    fmt.println("glfw_error:", error, "description:", description)
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height : i32) {
    framebuffer_size_x = width
    framebuffer_size_y = height

    context = runtime.default_context()
    assert(framebuffer_size_x > 0 && framebuffer_size_y > 0)
    framebuffer_aspect = f32(framebuffer_size_x) / f32(framebuffer_size_y)

    OpenGL.Viewport(0,0, width, height)
}

glfw_scroll_callback :: proc "c" (window : glfw.WindowHandle, xOffset, yOffset : f64){
    glfw_scroll.x = f32(xOffset)
    glfw_scroll.y = f32(yOffset)
}

glfw_drop_callback :: proc "c" (window: glfw.WindowHandle, count: c.int, paths: [^]cstring) {
    context = runtime.default_context()
    
    for i : c.int = 0; i < count; i += 1 {
        path := string(paths[i])
        append(&glfw_dropped_paths, path)
    }
}

init_glfw_window_hints :: proc() {
    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)

    when ODIN_OS == .Darwin do glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, OpenGL.TRUE)
}

init_glfw :: proc() -> bool {
    if !glfw.Init() {
        fmt.println("Failed to initialize glfw!")
        return false
    }


    glfw.SetErrorCallback(glfw_error)
    init_glfw_window_hints()

    return true
}

init_glfw_window :: proc(width, height : u16, title : string) -> bool {
    title_cstring, error := strings.clone_to_cstring(title)
    assert(error == nil)
    
    glfw_window = glfw.CreateWindow(c.int(width), c.int(height), title_cstring, nil, nil)
    if glfw_window == nil {
        fmt.printfln("Failed to create glfw_window!")
        return false
    }

    glfw.MakeContextCurrent(glfw_window)
    glfw.SwapInterval(1)
    
    OpenGL.load_up_to(int(GL_VERSION_MAJOR), int(GL_VERSION_MINOR), glfw.gl_set_proc_address)
    glfw_framebuffer_size_callback(glfw_window, c.int(width), c.int(height))

    glfw.SetFramebufferSizeCallback(glfw_window, glfw_framebuffer_size_callback)
    glfw.SetScrollCallback(glfw_window, glfw_scroll_callback)
    glfw.SetDropCallback(glfw_window, glfw_drop_callback)
    
    return true
}

glfw_process_callbacks :: proc (state : ^app_state) {
    if len(glfw_dropped_paths) == 0 do return

    for file_path, index in glfw_dropped_paths {
        fmt.printfln("Dropped file: %v", file_path)
        extension := filepath.ext(file_path)
        if strings.to_lower(extension) == ".png" {
            texture, texture_success := load_texture(file_path)
            if !texture_success {
                fmt.printfln("Failed to load texture: %v", file_path)
                continue
            }
            append(&state.textures, texture)
        }
    }

    clear(&glfw_dropped_paths)
}