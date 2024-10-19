package aabb_editor
import "core:strings"
import "core:os"
import "core:fmt"
import "core:path/filepath"

base_path : string

init_base_path :: proc () {
    assert(len(os.args) >= 1)

    when ODIN_OS == .Darwin do executable_path := os.args[0]
    else when ODIN_OS == .Windows{
        executable_path, new_allocation := filepath.to_slash(os.args[0])
    } else do panic("No basepath implementation for this platform!")
    
    executable_dir := filepath.dir(executable_path) 
    base_path = filepath.dir(executable_dir)
    delete(executable_dir)
}

cleanup_base_path :: proc () {
    delete(base_path)

}

from_base_path :: proc(file_path : string) -> string {
    combined_str := []string { base_path, "/", file_path}

    when ODIN_OS == .Windows do str := filepath.join(combined_str)
    else when ODIN_OS == .Darwin || ODIN_OS == .Linux {
        str, err := filepath.join(combined_str)
        assert(err == nil)
    } else do panic("Platform not supported:", ODIN_OS)

    return str
} 