package aabb_editor
import "core:strings"
import "core:os"
import "core:fmt"
import "core:path/filepath"

base_path : string

init_base_path :: proc () {
    assert(len(os.args) >= 1)

    when ODIN_OS == .Darwin do executable_path := os.args[0]
    else when ODIN_OS == .Windows do executable_path := filepath.to_slash(os.args[0])
    else do panic("No basepath implementation for this platform!")
    
    executable_dir := filepath.dir(executable_path) 
    base_path = filepath.dir(executable_dir)
}

from_base_path :: proc(file_path : string) -> string {
     
    combined_str := []string { base_path, "/", file_path}
    str, err := filepath.join(combined_str)
    assert(err == nil)

    return str
} 