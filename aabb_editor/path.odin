package aabb_editor
import "core:strings"

base_path : string

init_base_path :: proc () {
    base_path = "/Users/daniel/Dev/Learn/LearnOdin/"//TODO: proper setup
}

from_base_path :: proc(file_path : string) -> string {
    combined_str := []string { base_path, file_path}
    str, err := strings.concatenate(combined_str)
    assert(err == nil)
    return str
} 