#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 tint;
    vec2 resolution;
    vec2 windowSize;
    float radius;
    float reach;
    float strength;
    float softness;
};

// How far a pixel is from the window's rounded edge, negative means inside
float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

// Light that starts at the edge and dies away, leaving the window itself untouched
void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * resolution;
    float d = roundedBox(p, windowSize * 0.5, radius);
    float outside = smoothstep(-0.5, 0.5, d);
    float t = clamp(d / reach, 0.0, 1.0);
    float light = pow(1.0 - t, softness) * strength * outside;
    fragColor = vec4(tint.rgb * light, light) * qt_Opacity;
}
