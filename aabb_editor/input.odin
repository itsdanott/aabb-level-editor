package aabb_editor
import "vendor:glfw"
import "core:math/bits"

input_state :: struct {
    keys : map[i32]input_key_state,
}

input_key_state :: struct {
    was_pressed, is_pressed, is_start_press, is_release_press : bool,
    listeners : u16,
}

@(private)
make_input_state :: proc() -> input_state {
    return {
        keys = make(map[i32]input_key_state),
    }
}

cleanup_input :: proc (state : ^app_state){
    delete(state.input.keys)
}

@(private="file")
increment_input_key_listeners :: proc(key_state : input_key_state) -> input_key_state {
    assert(key_state.listeners + 1 < bits.U16_MAX)
    return {
        was_pressed = key_state.was_pressed,
        is_pressed = key_state.is_pressed,
        is_start_press = key_state.is_start_press,
        is_release_press  = key_state.is_release_press,
        listeners = key_state.listeners + 1,
    }
}

@(private)
listen_for_input_key :: proc (key : i32, state : ^app_state) {
    assert(key >= glfw.KEY_SPACE && key < glfw.KEY_LAST)
    key_state, ok := state.input.keys[key]
    if !ok {
        state.input.keys[key] = {
            listeners = 1,
        }
    } else {
        //TODO: figure out this workaround is really required(from the overview: "assigning to a struct field is prohibited.")
        //(initially I wanted to increment per ref)
        state.input.keys[key] = increment_input_key_listeners(key_state)
    }
}

@(private)
input_key_state_update :: proc(input : ^input_key_state, is_pressed : bool) {
    input.is_pressed = is_pressed
    input.is_start_press = false
    input.is_release_press = false

    if input.is_pressed {
        input.is_start_press = !input.was_pressed
        if input.is_start_press do input.was_pressed = true
    } else if input.was_pressed {
        input.was_pressed = false
        input.is_release_press = true
    }
}