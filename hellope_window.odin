package main

import "core:fmt"
import "core:c"
import "core:os"
import "hellope_package"
import "vendor:glfw"
import "vendor:OpenGL"
import "base:runtime"
import "aabb_editor"
import "core:strings"

vec3 :: struct {
    x, y, z : f32
}

GL_VERSION_MAJOR : c.int : 4
GL_VERSION_MINOR : c.int : 1

glfw_error :: proc "c" (error : c.int, description : cstring) {
    context = runtime.default_context()
    fmt.println("glfw_error:", error, "description:", description)
}

glfw_framebuffer_size_callback :: proc "c" (window: glfw.WindowHandle, width, height : i32) {
    OpenGL.Viewport(0,0, width, height)
}


check_for_supported_platform :: proc () {
    when !(ODIN_OS == .Darwin || ODIN_OS == .Windows || ODIN_OS == .Linux) {
        fmt.panicf("Unsupported Platform: %s", ODIN_OS)
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
        fmt.printfln("Failed to create glfw_window!");
        return false;
    }

    glfw.MakeContextCurrent(glfw_window)
    glfw.SwapInterval(1)
    glfw.SetFramebufferSizeCallback(glfw_window, glfw_framebuffer_size_callback)

    return true
}

glfw_window : glfw.WindowHandle = nil

main :: proc() {
    check_for_supported_platform()
    aabb_editor.init_base_path()

    if !init_glfw() do return
    defer glfw.Terminate()

    if !init_glfw_window(800, 600, "Hellope Odin") do return
    defer glfw.DestroyWindow(glfw_window)
    

    OpenGL.load_up_to(int(GL_VERSION_MAJOR), int(GL_VERSION_MINOR), glfw.gl_set_proc_address)
    
    texture, texture_success := aabb_editor.load_texture("rabbyte_logo_512.png")
    if !texture_success do return
    defer free(texture)

    shader, shader_success := aabb_editor.load_shader_from_files("shaders/simple.vert.glsl", "shaders/simple.frag.glsl")
    if !shader_success do return
    defer free(shader)

    vertices : []f32 = {
        //Position(XY)  TexCoord(XY)
        -1.0,  -1.0,       0,      0,
         1.0,  -1.0,     1.0,      0,
         1.0,   1.0,     1.0,    1.0,

         1.0,   1.0,     1.0,    1.0,
        -1.0,   1.0,       0,    1.0,
        -1.0,  -1.0,       0,      0,
    }

    vao, vbo : u32

    OpenGL.GenBuffers(1, &vbo)
    OpenGL.GenVertexArrays(1, &vao)

    defer OpenGL.DeleteBuffers(1, &vbo)
    defer OpenGL.DeleteVertexArrays(1, &vao)

    OpenGL.BindVertexArray(vao)
    OpenGL.BindBuffer(OpenGL.ARRAY_BUFFER, vbo)
    OpenGL.BufferData(OpenGL.ARRAY_BUFFER, size_of(vertices), &vertices, OpenGL.STATIC_DRAW)

    OpenGL.EnableVertexAttribArray(0)
    OpenGL.VertexAttribPointer(0, 2, OpenGL.FLOAT, OpenGL.FALSE, 4 * size_of(f32), uintptr(0))

    OpenGL.EnableVertexAttribArray(1)
    OpenGL.VertexAttribPointer(1, 2, OpenGL.FLOAT, OpenGL.FALSE, 4 * size_of(f32), uintptr(2 * size_of(f32)))


    shader_texture_location := OpenGL.GetUniformLocation(shader.id, "screenTexture")
    for !glfw.WindowShouldClose(glfw_window) {

        OpenGL.ClearColor(0.25, 0.25, 0.5, 1.0)
        OpenGL.Clear(OpenGL.COLOR_BUFFER_BIT)

        glfw.PollEvents()

        OpenGL.UseProgram(shader.id)
        OpenGL.ActiveTexture(OpenGL.TEXTURE0)
        OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)
        OpenGL.BindVertexArray(vao)

        OpenGL.Uniform1i(shader_texture_location, 0);
        OpenGL.DrawArrays(OpenGL.TRIANGLES, 0, 6)

        glfw.SwapBuffers(glfw_window);
    }
}