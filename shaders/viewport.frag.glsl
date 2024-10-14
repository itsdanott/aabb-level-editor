#version 410 core

out vec4 FragColor;

in vec2 TexCoords;

uniform sampler2D viewportTexture;

void main()
{
    FragColor = texture(viewportTexture, TexCoords);
}
