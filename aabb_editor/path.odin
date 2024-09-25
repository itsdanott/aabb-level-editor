package aabb_editor
import "core:strings"

base_path : string

init_base_path :: proc () {
    //TODO: proper setup (base path determination)
    when ODIN_OS == .Darwin do base_path = "/Users/daniel/Dev/Learn/LearnOdin/" 
    else when ODIN_OS == .Windows do base_path = "E:/Dev/Learn/LearnOdin/"
    else do panic("No basepath implementation for this platform!")
}

from_base_path :: proc(file_path : string) -> string {
    combined_str := []string { base_path, file_path}
    str, err := strings.concatenate(combined_str)
    assert(err == nil)
    return str
} 