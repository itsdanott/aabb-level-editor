package aabb_editor
import gl "vendor:OpenGL"

brush_renderer_state :: struct { 
    vao, vbo, ebo : u32,
}

make_brush_renderer_state :: proc () -> brush_renderer_state {
    return {}
}

init_brush_renderer :: proc (state : ^app_state) {
    gl.GenVertexArrays(1, &state.brush_renderer.vao)
    gl.GenBuffers(1, &state.brush_renderer.vbo)

    gl.BindVertexArray(state.brush_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.brush_renderer.vbo)
    gl.BufferData(gl.ARRAY_BUFFER, size_of(brush_vertex) * 6 * 6,nil, gl.STATIC_DRAW)
    
    gl.EnableVertexAttribArray(0)
    gl.VertexAttribPointer(0, 2, gl.FLOAT, gl.FALSE, size_of(brush_vertex), 0)
    
    gl.EnableVertexAttribArray(1)
    gl.VertexAttribIPointer(1, 1, gl.INT, size_of(brush_vertex), 2 * size_of(f32))

    gl.EnableVertexAttribArray(2)
    gl.VertexAttribIPointer(2, 1, gl.INT, size_of(brush_vertex), 2 * size_of(f32) + size_of(i32))
}

cleanup_brush_renderer :: proc (state : ^app_state) {
    gl.DeleteVertexArrays(1, &state.brush_renderer.vao)
    gl.DeleteBuffers(1, &state.brush_renderer.vbo)
}

texcoord_mode :: enum {
    WORLD_SPACE,
    TEX_COORDS,
}

brush_face :: struct {
    has_texture : bool,
    texture_id : int,
    texcoord_mode : texcoord_mode,
    color : vec3,

}
brush :: struct {
    min, max : vec3,
    faces : [6]brush_face,
    vertices : [6 * 6]brush_vertex,
}

brush_vertex :: struct {
    texcoord : vec2,
    vert_pos_index : i32,
    texture_id : i32,
}

AABB_VERTPOS_INDEX_LEFT_BOTTOM_FRONT : i32 : 0
AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT : i32 : 1
AABB_VERTPOS_INDEX_RIGHT_TOP_FRONT : i32 : 2
AABB_VERTPOS_INDEX_LEFT_TOP_FRONT : i32 : 3
AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK : i32 : 4
AABB_VERTPOS_INDEX_RIGHT_BOTTOM_BACK : i32 : 5
AABB_VERTPOS_INDEX_RIGHT_TOP_BACK : i32 : 6
AABB_VERTPOS_INDEX_LEFT_TOP_BACK : i32 : 7

create_brush_from_box_cursor :: proc (state : ^app_state) {
    brush := new(brush)
    brush^ = {
        min = state.box_cursor.min,
        max = state.box_cursor.max,
        vertices = {
            //AABB_FACE_INDEX_X_NEGATIVE: Triangle-Left-1
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_FRONT, 0},
            //AABB_FACE_INDEX_X_NEGATIVE: Triangle-Left-2
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_FRONT, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_BACK, 0},

            //AABB_FACE_INDEX_X_POSITIVE: Triangle-Right-1
            {{0, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_BACK, 0},
            //AABB_FACE_INDEX_X_POSITIVE: Triangle-Right-2
            {{0, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_BACK, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_FRONT, 0},
            
            //AABB_FACE_INDEX_Y_NEGATIVE : Triangle-Bottom-1
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT, 0},
            //AABB_FACE_INDEX_Y_NEGATIVE : Triangle-Bottom-2
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_FRONT, 0},
            
            //AABB_FACE_INDEX_Y_POSITIVE : Triangle-Top-1
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_TOP_FRONT, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_RIGHT_TOP_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_BACK, 0},
            //AABB_FACE_INDEX_Y_POSITIVE : Triangle-Top-2
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_TOP_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_BACK, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_BACK, 0},

            //AABB_FACE_INDEX_Z_NEGATIVE: Triangle-Back-1
            {{0, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_BACK, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_BACK, 0},
            //AABB_FACE_INDEX_Z_NEGATIVE: Triangle-Back-2
            {{0, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_BACK, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_BACK, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_BACK, 0},

            //AABB_FACE_INDEX_Z_POSITIVE: Triangle-Front-1
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_FRONT, 0},
            {{1, 0}, AABB_VERTPOS_INDEX_RIGHT_BOTTOM_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_FRONT, 0},
            //AABB_FACE_INDEX_Z_POSITIVE: Triangle-Front-2
            {{0, 0}, AABB_VERTPOS_INDEX_LEFT_BOTTOM_FRONT, 0},
            {{1, 1}, AABB_VERTPOS_INDEX_RIGHT_TOP_FRONT, 0},
            {{0, 1}, AABB_VERTPOS_INDEX_LEFT_TOP_FRONT, 0},
        },
    }
    append(&state.brushes, brush)
}

cleanup_brushes :: proc (state : ^app_state){
    for brush in state.brushes {
        free(brush)
    }
    clear(&state.brushes)
}

draw_brushes :: proc(state : ^app_state){
    gl.FrontFace(gl.CCW)
    gl.Enable(gl.CULL_FACE)
    gl.Enable(gl.DEPTH_TEST)
    
    gl.UseProgram(state.shader.brush_shader.id)
    gl.ActiveTexture(gl.TEXTURE0)
    gl.BindTexture(gl.TEXTURE_2D_ARRAY, state.texture_array_id)
    gl.Uniform1i(state.shader.brush_shader_texture_array_location, 0)

    for brush in state.brushes {
        draw_brush(brush, state)
    }

    gl.Disable(gl.DEPTH_TEST)
    gl.Disable(gl.CULL_FACE)
}

draw_brush :: proc(brush : ^brush, state : ^app_state) {
    pos := brush.min
    scale := brush.max - brush.min

    model : mat4 = create_model_matrix(pos, scale)
    gl.UniformMatrix4fv(state.shader.brush_shader_model_location, 1, false, &model[0][0])
    gl.UniformMatrix4fv(state.shader.brush_shader_view_location, 1, false, &state.camera.view_matrix[0][0])
    gl.UniformMatrix4fv(state.shader.brush_shader_projection_location, 1, false, &state.camera.projection_matrix[0][0])
    
    gl.BindVertexArray(state.brush_renderer.vao)
    gl.BindBuffer(gl.ARRAY_BUFFER, state.brush_renderer.vbo)
    gl.BufferSubData(gl.ARRAY_BUFFER, 0, size_of(brush_vertex) * 6 * 6, &brush.vertices)
    gl.DrawArrays(gl.TRIANGLES, 0, 6 * 6)
}

select_brush :: proc (brush : ^brush, state : ^app_state)  {
    state.box_cursor.min = brush.min
    state.box_cursor.max = brush.max

    state.selected_brush = brush
}

deselect_brush :: proc (state : ^app_state){
    state.selected_brush = nil
}

assign_texture_to_brush :: proc (brush : ^brush, array_texture_index : i32) {
    for &vertex in brush.vertices {
        vertex.texture_id = array_texture_index
    }
} 
assign_texture_to_brush_face :: proc (brush : ^brush, array_texture_index : i32, face_index : i32) {
    assert(face_index > -1)

    for i := face_index * 6; i < face_index * 6 + 6; i += 1 {
        brush.vertices[i].texture_id = array_texture_index
    }
} 