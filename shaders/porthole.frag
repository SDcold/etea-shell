#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 deep;
    vec4 tint;
    vec2 resolution;
    vec2 pointer;
    float time;
    float seed;
    float hover;
    float rise;
    float radius;
};

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

float noise(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

float cloud(vec2 p) {
    return noise(p) * 0.55 + noise(p * 2.1 + 3.7) * 0.28 + noise(p * 4.3 + 8.1) * 0.17;
}

float roundedBox(vec2 p, vec2 halfSize, float r) {
    vec2 q = abs(p) - halfSize + r;
    return length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - r;
}

float hills(float x, float offset) {
    return 0.5 * sin(x * 0.019 + offset) + 0.3 * sin(x * 0.047 + offset * 1.7) + 0.2 * sin(x * 0.113 + offset * 2.9) + 0.08 * sin(x * 0.31 + offset * 4.1);
}

// Every card is a little porthole onto the world outside: a sky that drifts and twinkles,
// lit from a horizon that rises and falls with whatever the card is about
void main() {
    vec2 px = qt_TexCoord0 * resolution;
    vec2 center = px - resolution * 0.5;

    // The fill doesn't quite match the ink line, like a print that's slightly off register
    float wobble = 1.1 * sin(px.x * 0.031 + seed) + 0.8 * sin(px.y * 0.053 + seed * 1.7);
    float d = roundedBox(center, resolution * 0.5, radius) + wobble;
    float alpha = smoothstep(0.8, -0.8, d);

    float horizon = resolution.y * (1.0 - rise);
    float height = clamp((horizon - px.y) / resolution.y, 0.0, 1.0);

    vec3 color = mix(deep.rgb, mix(deep.rgb, tint.rgb, 0.3), exp(-height * 8.0));

    // The nebula, folded over itself so it never looks like plain noise
    vec2 drift = vec2(time * 0.011, -time * 0.007);
    vec2 q = px / 170.0 + seed;
    float fold = cloud(q * 0.8 + drift);
    float gas = cloud(q + fold * 1.7 - drift * 0.6);
    color += tint.rgb * pow(gas, 3.0) * (0.3 + 0.6 * exp(-height * 5.0));

    // Stars, each one breathing at its own pace
    vec2 cell = floor(px / 5.0);
    float chance = hash(cell + seed);
    if (chance > 0.984) {
        float pace = hash(cell * 1.7);
        float breath = 0.5 + 0.5 * sin(time * (0.5 + 1.8 * pace) + pace * 40.0);
        vec2 spot = fract(px / 5.0) - 0.5 + (vec2(hash(cell + 2.0), hash(cell + 5.0)) - 0.5) * 0.4;
        float dot = smoothstep(0.34, 0.06, length(spot));
        color += vec3(1.0, 0.96, 0.9) * dot * (0.12 + breath * 0.5) * smoothstep(0.0, 0.2, height);
    }

    // The ridgelines, and the light pooling just above them
    float far = horizon + 3.5 * hills(px.x, seed);
    float near = horizon + 8.0 + 3.5 * hills(px.x, seed + 2.4);
    color += tint.rgb * exp(-max(far - px.y, 0.0) / 18.0) * 0.3;
    color = mix(color, mix(deep.rgb, tint.rgb, 0.3) * 0.75, smoothstep(0.7, -0.7, far - px.y));
    color = mix(color, deep.rgb * 0.55, smoothstep(0.7, -0.7, near - px.y));

    // Light follows the pointer around
    float toPointer = length(px - pointer);
    color += tint.rgb * exp(-toPointer * toPointer / 16000.0) * 0.16 * hover;

    color += (hash(floor(px)) - 0.5) * 0.028;
    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
