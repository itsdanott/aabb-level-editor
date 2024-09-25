#version 410 core

out vec4 FragColor;

in vec2 TexCoords;
uniform sampler2D screenTexture;

void main()
{
    vec4 color = texture(screenTexture, TexCoords);
    FragColor = color;
    //FragColor = vec4(1.0, 0.0, 0.0, 1.0);//color;
    //Optimization-01: Measure difference between GL_BLEND and discard in shader
    //if(color.a < 0.1)
    //    discard;
}
