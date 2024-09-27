package aabb_editor

import "core:path/filepath"
import "core:strings"
import "vendor:stb/image"
import "core:c"
import "core:fmt"
import "vendor:OpenGL"

texture :: struct {
    width, height : u16,
    channels : u8,
    id : u32,
}

load_texture :: proc(file_path : string) -> (texture_out: ^texture, success: bool) {
    path, cstr_err := strings.clone_to_cstring(from_base_path(file_path))
    assert(cstr_err == nil)
    
    width, height, channels : c.int
    image.set_flip_vertically_on_load(1)
    raw_data : [^]byte = image.load(path, &width, &height, &channels, 0)

    if raw_data == nil {
        fmt.println("Failed to load texture: ", path)
        return nil, false
    }

    defer image.image_free(raw_data)

    texture := new(texture)
    
    texture.width = u16(width)
    texture.height = u16(height)
    texture.channels = u8(channels)

    OpenGL.GenTextures(1, &texture.id)
    OpenGL.BindTexture(OpenGL.TEXTURE_2D, texture.id)

    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_S, OpenGL.REPEAT)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_WRAP_T, OpenGL.REPEAT)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MIN_FILTER, OpenGL.LINEAR_MIPMAP_LINEAR)
    OpenGL.TexParameteri(OpenGL.TEXTURE_2D, OpenGL.TEXTURE_MAG_FILTER, OpenGL.LINEAR)

    OpenGL.TexImage2D(OpenGL.TEXTURE_2D, 0, OpenGL.RGB, width, height, 0, OpenGL.RGBA, OpenGL.UNSIGNED_BYTE, raw_data)
    OpenGL.GenerateMipmap(OpenGL.TEXTURE_2D)

    return texture, true
}

free_texture :: proc(texture : ^texture) { 
    assert(texture != nil)
    assert(texture.id > 0)
    OpenGL.DeleteTextures(1, &texture.id)
    free(texture)
}