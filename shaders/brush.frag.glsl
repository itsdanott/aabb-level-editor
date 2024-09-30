#version 410 core

out vec4 FragColor;

in vec2 TexCoords;
flat in int TextureId;

uniform sampler2DArray textureArray;

void main()
{
    vec3 color = texture(textureArray, vec3(TexCoords.x, TexCoords.y, TextureId)).rgb;
    FragColor = vec4(color, 1.0);
}
