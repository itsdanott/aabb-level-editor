#version 410 core

in vec3 FragPos;
out vec4 FragColor;

uniform vec3 viewPos;
uniform float gridAlpha;
uniform float gridFadeDist;
uniform vec3 checkerColor1;
uniform vec3 checkerColor2;


void main()
{
    // Floor the x and z positions and sum them
    float check = mod(floor(FragPos.x) + floor(FragPos.z), 2.0);
    
    // If check is 0, use white; if 1, use black
    vec3 color = mix(checkerColor1, checkerColor2, check);

    float distanceToCamera = length(viewPos.xz - FragPos.xz);

    FragColor = vec4(color, (1.0 - (distanceToCamera / gridFadeDist)) * gridAlpha);
    // FragColor = vec4(color, mix(0.0, 1.0, 1.0 - (distanceToCamera / 32.0)));
}