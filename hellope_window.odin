package main

import "core:fmt"
import "hellope_package"
import "vendor:glfw"
import "vendor:OpenGL"
import "core:c"
import "base:runtime"

GL_VERSION_MAJOR : c.int : 4
GL_VERSION_MINOR : c.int : 1

glfw_error :: proc "c" (error : c.int, description : cstring) {
    context = runtime.default_context()
    fmt.println("glfw_error:", error, "description:", description)
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height : i32) {
    OpenGL.Viewport(0,0, width, height)
}

main :: proc() {
    constant_hello_str : string : "Hellope!"

    // hello_str := "Hellope!"
    // hello_str_len := len(hello_str)
    // fmt.printfln("This is '%s', it has a length of %i and test_integer is %i", hello_str, hello_str_len, sh.test_integer )

    // str: string = "Some text"

    // for character in str {
    //     assert(type_of(character) != rune)
    //     fmt.println(character)
    // }

    // test_array := [4]int{}

    // for i := 0; i < 10; i += 1 {
    //     fmt.println("Hello")
    // }

    // for &value, index in test_array {
    //     fmt.printfln("Before [%i] = Value: %i", index, value)
    //     value = index
    //     fmt.printfln("After  [%i] = Value: %i", index, value)
    // }


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

    for !glfw.WindowShouldClose(glfw_window) {

        OpenGL.ClearColor(0.25, 0.25, 0.5, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        glfw.PollEvents()

        glfw.SwapBuffers(glfw_window);
    }
}