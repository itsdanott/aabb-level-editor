package aabb_editor

import "core:math"

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// aabb - constants
AABB_FACE_INDEX_X_NEGATIVE :: 0
AABB_FACE_INDEX_X_POSITIVE :: 1

AABB_FACE_INDEX_Y_NEGATIVE :: 2
AABB_FACE_INDEX_Y_POSITIVE :: 3

AABB_FACE_INDEX_Z_NEGATIVE :: 4
AABB_FACE_INDEX_Z_POSITIVE :: 5

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// aabb - types
aabb :: struct {
    min, max : vec3,
}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// aabb - procs
aabb_face_index_to_axis :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case 0..<2: //X
        return {1.0, 0.0, 0.0}
    case 2..<4: //Y
        return {0.0, 1.0, 0.0}
    case 4..<6: //Z
        return {0.0, 0.0, 1.0}
    case: panic("aabb face index out of range!")
    }
}

aabb_face_index_to_normal :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE: return vec3{-1,0,0}
    case AABB_FACE_INDEX_X_POSITIVE: return vec3{1,0,0}
    case AABB_FACE_INDEX_Y_NEGATIVE: return vec3{0,-1,0}
    case AABB_FACE_INDEX_Y_POSITIVE: return vec3{0,1,0}
    case AABB_FACE_INDEX_Z_NEGATIVE: return vec3{0,0,-1}
    case AABB_FACE_INDEX_Z_POSITIVE: return vec3{0,0,1}
    case: panic("aabb face index out of range!")
    }
}

aabb_face_index_to_perpendicular_plane_normal :: proc (face_index : i32) -> vec3 {
    switch face_index {
    case AABB_FACE_INDEX_X_NEGATIVE:
        return {1,0,0}
    case AABB_FACE_INDEX_X_POSITIVE:
        return {1,0,0}
    case AABB_FACE_INDEX_Y_NEGATIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Y_POSITIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Z_NEGATIVE:
        return {0,0,1}
    case AABB_FACE_INDEX_Z_POSITIVE:
        return {0,0,1}
    case:
        panic("invalid selected_face_index")
    }
}

aabb_fix_min_max :: proc(aabb : ^aabb) {
    aabb^ = {
        min = vec3 {
            math.min(aabb.min.x, aabb.max.x),
            math.min(aabb.min.y, aabb.max.y),
            math.min(aabb.min.z, aabb.max.z),
        },
        max = vec3 {
            math.max(aabb.min.x, aabb.max.x),
            math.max(aabb.min.y, aabb.max.y),
            math.max(aabb.min.z, aabb.max.z),
        },
    }
}

aabb_get_size :: proc(aabb : aabb) -> vec3 {
    return aabb.max-aabb.min
}