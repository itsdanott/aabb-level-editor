package aabb_editor

import "core:os"
import "base:runtime"
import "core:fmt"
import "vendor:OpenGL"
import "core:strings"
import "core:io"

shader :: struct {
    id : u32,
}

shader_type :: enum {
    VERTEX_SHADER,
    FRAGMENT_SHADER,
}

global_shader_state :: struct {
    unlit_color_shader : ^shader,
    unlit_color_shader_color_location, unlit_color_model_location, unlit_color_view_location, 
        unlit_color_projection_location : i32, 
    brush_shader : ^shader,
    brush_shader_model_location, brush_shader_view_location, brush_shader_projection_location, 
        brush_shader_texture_array_location : i32, 
}

make_global_shader_state :: proc () -> global_shader_state {
    return {}
}

init_global_shaders :: proc(state : ^app_state) -> bool {
    unlit_color_shader_success : bool
    state.shader.unlit_color_shader, unlit_color_shader_success = load_shader_from_files(
        "shaders/unlit_color.vert.glsl", "shaders/unlit_color.frag.glsl")
    if !unlit_color_shader_success do return false

    state.shader.unlit_color_shader_color_location = OpenGL.GetUniformLocation(state.shader.unlit_color_shader.id,
        "color")
    state.shader.unlit_color_model_location = OpenGL.GetUniformLocation(state.shader.unlit_color_shader.id, "model")
    state.shader.unlit_color_view_location = OpenGL.GetUniformLocation(state.shader.unlit_color_shader.id, "view")
    state.shader.unlit_color_projection_location = OpenGL.GetUniformLocation(state.shader.unlit_color_shader.id,
        "projection")

    brush_shader_success : bool
    state.shader.brush_shader, brush_shader_success = load_shader_from_files("shaders/brush.vert.glsl",
        "shaders/brush.frag.glsl")
    if !brush_shader_success do return false
    
    state.shader.brush_shader_model_location = OpenGL.GetUniformLocation(state.shader.brush_shader.id, "model")
    state.shader.brush_shader_view_location = OpenGL.GetUniformLocation(state.shader.brush_shader.id, "view")
    state.shader.brush_shader_projection_location = OpenGL.GetUniformLocation(state.shader.brush_shader.id, 
        "projection")
    state.shader.brush_shader_texture_array_location = OpenGL.GetUniformLocation(state.shader.brush_shader.id,
        "textureArray")

    return true
}

free_global_shaders :: proc(state : ^app_state) {
    free_shader(state.shader.unlit_color_shader)
    free_shader(state.shader.brush_shader)
}

load_shader_source :: proc (file_path : string) -> (source: string, success: bool) {
    context = runtime.default_context()
    
    str_data, str_ok := os.read_entire_file(from_base_path(file_path), context.allocator)
    if !str_ok {
        fmt.println("load_shader_source - invalid:", file_path)
        return "", false
    }

    //TODO: check leak - see if delete(str_data, context.allocator) is required elsewhere
    return string(str_data), true
}

load_shader_from_files :: proc (vert_source_file_path, frag_source_file_path : string) -> (shader: ^shader, 
success: bool) {
    vert_source, vert_source_ok := load_shader_source(vert_source_file_path)
    frag_source, frag_source_ok := load_shader_source(frag_source_file_path)
    if !vert_source_ok || !frag_source_ok do return nil, false

    return load_shader(vert_source, frag_source)
}

info_log_size :: 1024
@(private="file")
check_shader_compilation :: proc(shader_id : u32) -> bool {
    if shader_id == 0 do return false

    is_success : i32
    OpenGL.GetShaderiv(shader_id, OpenGL.COMPILE_STATUS, &is_success)

    if is_success == 0 {
        info_log := make([^]u8, info_log_size)
        defer free(info_log)
        OpenGL.GetShaderInfoLog(shader_id, info_log_size, nil, info_log)
        info_log_cstring := cstring(info_log)
        fmt.println("check_shader_compilation - failed, shader_id:", shader_id, "info_log:\n", info_log_cstring) 
        return false
    }
    return true
}

@(private="file")
check_shader_program_link_status :: proc(shader_program : u32) -> bool {
    success : i32 = 0
    OpenGL.GetProgramiv(shader_program, OpenGL.LINK_STATUS, &success)

    if success == 0 {
        info_log := make([^]u8, info_log_size)
        defer free(info_log)
        OpenGL.GetProgramInfoLog(shader_program, info_log_size, nil, info_log)
        info_log_cstring := cstring(info_log)
        fmt.println("check_shader_program_link_status - failed, shader_program:", shader_program, "info_log:\n",
            info_log_cstring)
        return false
    }

    return true
}

@(private="file")
get_opengl_shader_type :: proc(shader_type: shader_type) -> u32 {
    switch shader_type {
    case .VERTEX_SHADER:
        return OpenGL.VERTEX_SHADER
    case .FRAGMENT_SHADER:
        return OpenGL.FRAGMENT_SHADER
    }

    panic("invalid shader type")
}

@(private="file")
compile_shader :: proc(shader_source : string, shader_type: shader_type) -> (shader_id: u32, success: bool) {
    shader_id = OpenGL.CreateShader(get_opengl_shader_type(shader_type))
    source_cstr, cstr_err := strings.clone_to_cstring(shader_source)
    assert(cstr_err == nil)
    OpenGL.ShaderSource(shader_id, 1, &source_cstr, nil)
    OpenGL.CompileShader(shader_id)

    if !check_shader_compilation(shader_id) do return shader_id, false

    return shader_id, true
}

@(private="file")
compile_vertex_shader :: proc(shader_source: string) -> (shader_id: u32, success: bool) {
    return compile_shader(shader_source, shader_type.VERTEX_SHADER)
}

@(private="file")
compile_fragment_shader :: proc(shader_source: string) -> (shader_id: u32, success: bool) {
    return compile_shader(shader_source, shader_type.FRAGMENT_SHADER)
}

@(private="file")
load_shader :: proc (vert_source, frag_source : string) -> (shader_out: ^shader, success: bool) {
    vert_shader, vert_ok := compile_vertex_shader(vert_source)
    assert(vert_ok)
    defer OpenGL.DeleteShader(vert_shader)

    frag_shader, frag_ok := compile_fragment_shader(frag_source)
    assert(frag_ok)
    defer OpenGL.DeleteShader(frag_shader)

    shader_program := OpenGL.CreateProgram()
    if(shader_program == 0){
        fmt.printfln("Failed to create opengl shader program")
        return nil, false
    }

    OpenGL.AttachShader(shader_program, vert_shader)
    OpenGL.AttachShader(shader_program, frag_shader)
    OpenGL.LinkProgram(shader_program)
    if !check_shader_program_link_status(shader_program) {
        return nil, false
    }

    shader_out = new(shader)
    shader_out.id = shader_program

    return shader_out, true
}

free_shader :: proc (shader : ^shader) {
    assert(shader != nil)
    assert(shader.id > 0)
    OpenGL.DeleteProgram(shader.id)
    free(shader)
}