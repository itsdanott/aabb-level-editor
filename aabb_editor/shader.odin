package aabb_editor

import "core:os"
import "base:runtime"
import "core:fmt"
import "vendor:OpenGL"
import "core:strings"

shader :: struct {
    id : u32
}

shader_type :: enum {
    VERTEX_SHADER,
    FRAGMENT_SHADER
}

load_shader_source :: proc (file_path : string) -> (source: string, success: bool) {
    context = runtime.default_context()
    str_data, str_ok := os.read_entire_file(file_path, context.allocator)
    if !str_ok {
        fmt.println("load_shader_source - invalid:", file_path)
        return "", false
    }

    defer delete(str_data, context.allocator)
    vert_str := string(str_data)

    fmt.println("load_shader_source - success:", file_path)
    return vert_str, true
}

load_shader_from_files :: proc (vert_source_file_path, frag_source_file_path : string) -> (shader: ^shader, success: bool) {
    vert_source, vert_source_ok := load_shader_source(vert_source_file_path)
    frag_source, frag_source_ok := load_shader_source(vert_source_file_path)
    if !vert_source_ok || !frag_source_ok {
        return nil, false
    }

    return load_shader(vert_source, frag_source)
}

check_shader_compilation :: proc(shader_id : u32) -> bool {
    return true
}

get_opengl_shader_type :: proc(shader_type: shader_type) -> u32 {
    switch shader_type {
        case .VERTEX_SHADER:
            return OpenGL.VERTEX_SHADER
        case .FRAGMENT_SHADER:
            return OpenGL.FRAGMENT_SHADER
    }

    panic("invalid shader type")
}

compile_shader :: proc(shader_source : string, shader_type: shader_type) -> (shader_id: u32, success: bool) {
    shader_id = OpenGL.CreateShader(get_opengl_shader_type(shader_type))
    vert_source_cstr := strings.clone_to_cstring(shader_source, context.allocator)
    OpenGL.ShaderSource(shader_id, 1, &vert_source_cstr, nil)
    OpenGL.CompileShader(shader_id)

    if !check_shader_compilation(shader_id) {
        return shader_id, false
    }

    return shader_id, true
}

compile_vertex_shader :: proc(shader_source: string) -> (shader_id: u32, success: bool) {
    return compile_shader(shader_source, shader_type.VERTEX_SHADER)
}
compile_fragment_shader :: proc(shader_source: string) -> (shader_id: u32, success: bool) {
    return compile_shader(shader_source, shader_type.FRAGMENT_SHADER)
}

load_shader :: proc (vert_source, frag_source : string) -> (shader: ^shader, success: bool) {
    
    vert_shader := OpenGL.CreateShader(OpenGL.VERTEX_SHADER)
    vert_source_cstr := strings.clone_to_cstring(vert_source, context.allocator)
    OpenGL.ShaderSource(vert_shader, 1, &vert_source_cstr, nil)
    OpenGL.CompileShader(vert_shader)
    if !check_shader_compilation(vert_shader) {
        return nil, false
    }

    return nil, true
}