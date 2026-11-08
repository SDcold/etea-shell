#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    vec2 pictureSize;
    float grain;
    float space; // 0 on the ground, 1 once we've left the atmosphere
};

layout(binding = 1) uniform sampler2D picture;

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

// Your own picture as the sky: it covers the screen without stretching, then gets the
// same grain and the same night above the atmosphere as the painted skies
void main() {
    vec2 size = max(pictureSize, vec2(1.0));
    vec2 shown = size * max(resolution.x / size.x, resolution.y / size.y);
    vec2 uv = (qt_TexCoord0 * resolution - (resolution - shown) * 0.5) / shown;
    vec3 color = texture(picture, uv).rgb;

    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));
    color = mix(color, overlay(color, n), grain) + (n - 0.5) * grain * 0.065;

    vec2 cell = floor(qt_TexCoord0 * resolution / 2.0);
    float star = step(0.9972, hash(cell + 3.7)) * (0.35 + 0.65 * hash(cell + 11.0));
    color = mix(color, vec3(0.02, 0.024, 0.05) + n * 0.012, space) + star * space;
    fragColor = vec4(color, 1.0) * qt_Opacity;
}
