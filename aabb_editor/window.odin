package aabb_editor

import "vendor:glfw"
import "core:strings"
import "core:fmt"
import "base:runtime"
import "vendor:OpenGL"
import "core:c"

GL_VERSION_MAJOR : c.int : 4
GL_VERSION_MINOR : c.int : 1
glfw_window : glfw.WindowHandle = nil

glfw_error :: proc "c" (error : c.int, description : cstring) {
    context = runtime.default_context()
    fmt.println("glfw_error:", error, "description:", description)
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height : i32) {
    OpenGL.Viewport(0,0, width, height)
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
    glfw.SetFramebufferSizeCallback(glfw_window, glfw_framebuffer_size_callback)
    
    OpenGL.load_up_to(int(GL_VERSION_MAJOR), int(GL_VERSION_MINOR), glfw.gl_set_proc_address)

    return true
}