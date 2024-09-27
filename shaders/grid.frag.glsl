#version 410 core

in vec3 FragPos;
out vec4 FragColor;

uniform vec3 viewPos;
uniform float gridScale;

const vec3 colorBlack = vec3(0.0);
const vec3 colorWhite = vec3(1.0);


void main()
{
    // Floor the x and z positions and sum them
    float check = mod(floor(FragPos.x) + floor(FragPos.z), 2.0);
    
    // If check is 0, use white; if 1, use black
    vec3 color = mix(colorWhite, colorBlack, check);

    float distanceToCamera = length(viewPos - FragPos);

    FragColor = vec4(color, mix(0.0, 1.0, 1.0 / distanceToCamera));
}