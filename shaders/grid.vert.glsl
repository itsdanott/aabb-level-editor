#version 410 core

layout (location = 0) in vec3 inPos;

uniform mat4 model;
uniform mat4 view;
uniform mat4 projection;

out vec3 FragPos;

void main()
{
    vec4 worldPos = model * vec4(inPos, 1.0);
    gl_Position = projection * view * worldPos;
    FragPos = vec3(worldPos);
}