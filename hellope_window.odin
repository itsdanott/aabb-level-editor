package main

import "core:fmt"
import "core:c"
import "core:os"
import "hellope_package"
import "vendor:glfw"
import "vendor:OpenGL"
import "base:runtime"
import "aabb_editor"


GL_VERSION_MAJOR : c.int : 4
GL_VERSION_MINOR : c.int : 1

glfw_error :: proc "c" (error : c.int, description : cstring) {
    context = runtime.default_context()
    fmt.println("glfw_error:", error, "description:", description)
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height : i32) {
    OpenGL.Viewport(0,0, width, height)
}

base_path : string

init_base_path :: proc () {
    base_path = "test"
}

main :: proc() {
    fmt.println("Max-Value: i8", max(i8))
    fmt.println("Max-Value: i16", max(i16))
    fmt.println("Max-Value: i32", max(i32))
    fmt.println("Max-Value: i64", max(i64))

    fmt.println("Max-Value: u8", max(u8))
    fmt.println("Max-Value: u16", max(u16))
    fmt.println("Max-Value: u32", max(u32))
    fmt.println("Max-Value: u64", max(u64))

    fmt.println("BasePath:", base_path)
    init_base_path()
    fmt.println("BasePath:", base_path)
    constant_hello_str : string : "Hellope!"

    context = runtime.default_context()
    glfw.WindowHint(glfw.RESIZABLE, 1)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MINOR, GL_VERSION_MAJOR)
    glfw.WindowHint(glfw.CONTEXT_VERSION_MAJOR, GL_VERSION_MINOR)
    glfw.WindowHint(glfw.OPENGL_PROFILE, glfw.OPENGL_CORE_PROFILE)
    //TODO: apple only:
    glfw.WindowHint(glfw.OPENGL_FORWARD_COMPAT, OpenGL.TRUE)

    
    if glfw.Init() == false {
        return;    
    }


    defer glfw.Terminate()
    glfw.SetErrorCallback(glfw_error)
    
    glfw_window := glfw.CreateWindow(800, 600, "Hellopoe Odin!", nil, nil)
    defer glfw.DestroyWindow(glfw_window)
    
    if glfw_window == nil {
        fmt.printfln("Failed to create glfw_window");
        return;
    }
    
    glfw.MakeContextCurrent(glfw_window)
    glfw.SwapInterval(1)

    glfw.SetFramebufferSizeCallback(glfw_window, glfw_framebuffer_size_callback)
    

    OpenGL.load_up_to(int(GL_VERSION_MAJOR), int(GL_VERSION_MINOR), glfw.gl_set_proc_address)
    
    fmt.printfln("Successfully created glfw_window");
    
    //TODO: getting base, executable, appdata paths


    texture := aabb_editor.load_texture("rabbyte_logo_512.png")
    
    for !glfw.WindowShouldClose(glfw_window) {

        OpenGL.ClearColor(0.25, 0.25, 0.5, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        glfw.PollEvents()

        glfw.SwapBuffers(glfw_window);
    }
}