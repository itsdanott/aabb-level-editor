package aabb_editor

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// app_state - constants
delta_time : f32 : 1.0 / 60.0

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// app_state - types
app_state :: struct {
    editor : editor_state,
    grid : grid_state,
    shader : global_shader_state,
    camera : camera,
    line_renderer : line_renderer_state,
    box_line_renderer : box_line_renderer_state,
    quad_renderer : quad_renderer_state,
    box_cursor : box_cursor_state,
    textures : [dynamic]^texture,
    brushes : [dynamic]^brush,
    brush_renderer : brush_renderer_state,
    texture_array_id : u32,
    selected_brush : ^brush,
    unique_brush_id_increment : u32,
    is_mouse_hit : bool, //TODO: to be used to get the aabb edge points
    input : input_state,
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// app_state - procs
make_app_state :: proc() -> app_state{
    return {
        editor = make_editor_state(),
        grid = make_grid_state(),
        shader = make_global_shader_state(),
        camera = make_default_cam(),
        line_renderer = make_line_renderer_state(),
        box_line_renderer = make_box_line_renderer_state(),
        quad_renderer = make_quad_renderer_state(),
        box_cursor = make_box_cursor_state(),
        brush_renderer = make_brush_renderer_state(),
        selected_brush = nil,
        input = make_input_state(),
    }
}