#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float from;
    float to;
};

layout(binding = 1) uniform sampler2D source;

// Solid at the top, then melting away downwards, same as the bars behind the hills
void main() {
    float fade = 1.0 - smoothstep(from, to, qt_TexCoord0.y);
    fragColor = texture(source, qt_TexCoord0) * fade * fade * qt_Opacity;
}
