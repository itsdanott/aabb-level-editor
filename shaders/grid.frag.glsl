// #version 410 core

// in vec3 FragPos;
// out vec4 FragColor;

// const float width = 0.1;

// void main()
// {
//     if(mod(abs(FragPos.x), 1.0) < width || mod(abs(FragPos.z), 1.0) < width)
//         FragColor = vec4(1.0, 0.0, 0.0, 1.0);
//     else
//         discard;
// }

#version 410 core

in vec3 FragPos;
out vec4 FragColor;

uniform vec3 viewPos;   // Camera/view position for perspective scaling
uniform float gridScale; // Scale of the grid based on distance

const float width = 0.1; // Grid line width

// void main()
// {
//     // Compute distance of FragPos to the camera to scale the grid based on distance
//     float distanceToCamera = length(viewPos - FragPos);

//     // Scale the grid size based on distance
//     float scaledWidth = width / (distanceToCamera * gridScale);

//     // Use mod to get the grid pattern
//     float lineX = abs(mod(FragPos.x, 1.0));
//     float lineZ = abs(mod(FragPos.z, 1.0));

//     // Use fwidth to calculate smooth transition for anti-aliasing
//     float aaWidthX = fwidth(lineX);
//     float aaWidthZ = fwidth(lineZ);

//     // Smooth step to blend the grid line smoothly based on its width and anti-aliasing
//     float blendX = smoothstep(scaledWidth - aaWidthX, scaledWidth + aaWidthX, lineX);
//     float blendZ = smoothstep(scaledWidth - aaWidthZ, scaledWidth + aaWidthZ, lineZ);

//     // Blend both X and Z lines to create the final grid pattern
//     float gridLine = 1.0 - min(blendX, blendZ);

//     // Set the color of the grid line (red) and blend it based on the gridLine value
//     FragColor = vec4(vec3(gridLine), gridLine);
// }

const vec3 colorBlack = vec3(0.0);
const vec3 colorWhite = vec3(1.0);
// void main()
// {
//     float lineX = abs(mod(floor(FragPos.x), 2.0));
//     float lineZ = abs(mod(floor(FragPos.z), 2.0));
//     FragColor = vec4(mix(colorBlack, colorWhite, mix(lineX, lineZ, 0.5)), 1.0);
//     // FragColor = vec4(mix(colorBlack, colorWhite, mix(lineX, lineZ, 0.5)), 1.0);
//     // float lineZ = abs(mod(FragPos.z, 1.0));

//     // float gridLine = 1.0 - min(lineX, lineZ);
//     // FragColor = vec4(vec3(gridLine), 1.0);
// }

void main()
{
    // Floor the x and z positions and sum them
    float check = mod(floor(FragPos.x) + floor(FragPos.z), 2.0);
    
    // If check is 0, use white; if 1, use black
    vec3 color = mix(colorWhite, colorBlack, check);

    float distanceToCamera = length(viewPos - FragPos);

    // Set the final fragment color
    FragColor = vec4(color, mix(0.0, 1.0, 1.0 / distanceToCamera));
}