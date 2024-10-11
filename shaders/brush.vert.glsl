#version 410 core

layout (location = 0) in vec2 inTexCoords;
layout (location = 1) in int inVertPosIndex;
layout (location = 2) in int inVertNormalIndex;
layout (location = 3) in int inTextureId;

out vec2 TexCoords;
flat out int TextureId;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

const vec3 vertexPositions[8] = vec3[]
(
vec3( 0.0,  0.0, 1.0),    //0 = left     bottom    front
vec3( 1.0,  0.0, 1.0),    //1 = right    bottom    front
vec3( 1.0,  1.0, 1.0),    //2 = right    top       front
vec3( 0.0,  1.0, 1.0),    //3 = left     top       front

vec3( 0.0,  0.0,  0.0),   //4 = left     bottom    back
vec3( 1.0,  0.0,  0.0),   //5 = right    bottom    back
vec3( 1.0,  1.0,  0.0),   //6 = right    top       back
vec3( 0.0,  1.0,  0.0)    //7 = left     top       back
);

const vec3 vertexNormals[6] = vec3[]
(
vec3(-1.0, 0.0, 0.0),
vec3( 1.0, 0.0, 0.0),
vec3( 0.0,-1.0, 0.0),
vec3( 0.0, 1.0, 0.0),
vec3( 0.0, 0.0,-1.0),
vec3( 0.0, 0.0, 1.0)
);

void main()
{
    vec3 inPos = vertexPositions[inVertPosIndex];
    gl_Position = projection * view * model * vec4(inPos, 1.0);

    vec3 worldPos = (model * vec4(inPos, 1.0)).xyz;    
    vec3 inNormal = vertexNormals[inVertNormalIndex];
    vec2 adjustedTexCoords;

    if (abs(inNormal.x) > 0.9) {
        adjustedTexCoords = worldPos.yz;
    } else if (abs(inNormal.y) > 0.9) { 
        adjustedTexCoords = worldPos.xz;
    } else {
        adjustedTexCoords = worldPos.xy;
    }
    
    TexCoords = adjustedTexCoords;
    TextureId = inTextureId;
}
