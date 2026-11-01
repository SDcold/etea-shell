#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 colorTop;
    vec4 colorMid;
    vec4 colorLow;
    vec2 resolution;
    float grain;
    float space; // 0 on the ground, 1 once we've left the atmosphere
};

// A bit of per-pixel randomness to make the grain from
float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

// The grain blends like an Overlay layer, just like in the mockup
vec3 overlay(vec3 base, float n) {
    return mix(2.0 * base * n, 1.0 - 2.0 * (1.0 - base) * (1.0 - n), step(0.5, base));
}

// The sky gradient, then the grain on top
void main() {
    float y = qt_TexCoord0.y;
    vec3 color = y < 0.62 ? mix(colorTop.rgb, colorMid.rgb, y / 0.62) : mix(colorMid.rgb, colorLow.rgb, min((y - 0.62) / 0.3, 1.0));

    float n = mix(0.376, 0.627, hash(floor(qt_TexCoord0 * resolution)));
    color = mix(color, overlay(color, n), grain) + n * 0.022;

    // Above the atmosphere the sky goes dark and the stars come out
    vec2 cell = floor(qt_TexCoord0 * resolution / 2.0);
    float star = step(0.9972, hash(cell + 3.7)) * (0.35 + 0.65 * hash(cell + 11.0));
    color = mix(color, vec3(0.02, 0.024, 0.05) + n * 0.012, space) + star * space;
    fragColor = vec4(color, 1.0) * qt_Opacity;
}
