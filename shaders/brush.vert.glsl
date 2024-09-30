#version 410 core

layout (location = 0) in vec2 inTexCoords;
layout (location = 1) in int inVertPosIndex;
layout (location = 2) in int inTextureId;

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

void main()
{
    vec3 inPos = vertexPositions[inVertPosIndex];
    gl_Position = projection * view * model * vec4(inPos, 1.0);
    TexCoords = inTexCoords;
    TextureId = inTextureId;
}
