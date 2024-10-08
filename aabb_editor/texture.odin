package aabb_editor

import "core:path/filepath"
import "core:strings"
import "vendor:stb/image"
import "core:c"
import "core:fmt"
import gl "vendor:OpenGL"

texture :: struct {
    width, height : i32,
    channels : u8,
    id : u32,
    is_in_array : bool,
    array_index : i32,
    raw_data : [^]byte,
}

load_texture_relative_path :: proc(file_path : string) -> (texture_out: ^texture, success: bool) {
    return load_texture(from_base_path(file_path))
}

load_texture :: proc(file_path : string) -> (texture_out: ^texture, success: bool) {
    path, cstr_err := strings.clone_to_cstring(file_path)
    assert(cstr_err == nil)
    
    width, height, channels : c.int
    image.set_flip_vertically_on_load(0)
    raw_data : [^]byte = image.load(path, &width, &height, &channels, 0)

    if raw_data == nil {
        fmt.println("Failed to load texture: ", path)
        return nil, false
    }

    texture := new(texture)
    
    texture.width = width
    texture.height = height
    texture.channels = u8(channels)
    texture.is_in_array = false
    texture.array_index = -1
    texture.raw_data = raw_data

    gl.GenTextures(1, &texture.id)
    gl.BindTexture(gl.TEXTURE_2D, texture.id)

    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    format : i32 = get_texture_format_from_channels(texture.channels)
    gl.TexImage2D(gl.TEXTURE_2D, 0, format, width, height, 0, u32(format), gl.UNSIGNED_BYTE, raw_data)
    gl.GenerateMipmap(gl.TEXTURE_2D)

    return texture, true
}

free_texture :: proc(texture : ^texture) { 
    assert(texture != nil)
    assert(texture.id > 0)
    gl.DeleteTextures(1, &texture.id)
    image.image_free(texture.raw_data)
    free(texture)
}

cleanup_textures :: proc(state : ^app_state) {
    for texture in state.textures {
        free_texture(texture)
    }
    clear(&state.textures)
}

generate_texture_array :: proc(state : ^app_state) {
    if state.texture_array_id != 0 {
        gl.DeleteTextures(1, &state.texture_array_id)
        state.texture_array_id = 0
    }
    
    if len(state.textures) == 0 do return
    array_textures := [dynamic]^texture{}
    reserve(&array_textures, len(state.textures))
    reference_texture :^texture = nil
    
    for texture in state.textures {
        texture.array_index = -1
        if texture.is_in_array {
            if reference_texture == nil do reference_texture = texture
            else if texture.width != reference_texture.width || texture.height != reference_texture.height || 
            texture.channels != reference_texture.channels {
                fmt.printfln("texture[%v] marked for array, but does not match reference texture (width, height, channels)", 
                    texture.id)
                continue
            }
            append(&array_textures, texture)
        }
    }

    gl.GenTextures(1, &state.texture_array_id)
    gl.BindTexture(gl.TEXTURE_2D_ARRAY, state.texture_array_id)
    format := get_texture_format_from_channels(reference_texture.channels)
    num_textures := len(array_textures)
    gl.TexImage3D(gl.TEXTURE_2D_ARRAY, 0, format, reference_texture.width, reference_texture.height, i32(num_textures),
        0, u32(format), gl.UNSIGNED_BYTE, nil)



    for texture, index in array_textures {
        gl.BindTexture(gl.TEXTURE_2D, texture.id)
        gl.TexSubImage3D(gl.TEXTURE_2D_ARRAY, 0,0,0, i32(index), reference_texture.width, reference_texture.height, 1,
            u32(format),gl.UNSIGNED_BYTE, texture.raw_data)
        texture.array_index = i32(index)
    }
    
    gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_S, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_WRAP_T, gl.REPEAT)
    gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MIN_FILTER, gl.LINEAR_MIPMAP_LINEAR)
    gl.TexParameteri(gl.TEXTURE_2D_ARRAY, gl.TEXTURE_MAG_FILTER, gl.LINEAR)

    gl.GenerateMipmap(gl.TEXTURE_2D_ARRAY)

    fmt.printfln("Generated Texture array with %v textures, ref: %v", len(array_textures), reference_texture)
}

get_texture_format_from_channels :: proc (channels : u8) -> i32 {
    switch channels {
    case 1:
        return gl.RED
    case 3:
        return gl.RGB
    case 4:
        return gl.RGBA
    case: panic("Invalid number of texture channels")
    }
}