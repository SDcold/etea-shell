#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 deep;
    vec4 tint;
    vec4 ink;
    vec4 anchorBox; // x, y, width, height, in this item's pixels
    vec4 panelBox;
    vec2 resolution;
    float anchorRadius;
    float panelRadius;
    float blend; // how far apart two shapes still melt into each other
    float anchorAmount; // 1 while the drop still clings to what opened it, 0 once it lets go
    float time;
    float seed;
    float rise;
    float inkAmount;
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

// Two shapes that melt into one where they come close, like two drops of water
float smoothUnion(float a, float b, float k) {
    float h = max(k - abs(a - b), 0.0) / k;
    return min(a, b) - h * h * k * 0.25;
}

float hills(float x, float offset) {
    return 0.5 * sin(x * 0.019 + offset) + 0.3 * sin(x * 0.047 + offset * 1.7) + 0.2 * sin(x * 0.113 + offset * 2.9);
}

// The panel is one liquid shape: the drop pulled out of the bar and the panel it grows into
void main() {
    vec2 px = qt_TexCoord0 * resolution;

    vec2 panelHalf = panelBox.zw * 0.5;
    float dPanel = roundedBox(px - panelBox.xy - panelHalf, panelHalf, min(panelRadius, min(panelHalf.x, panelHalf.y)));
    vec2 anchorHalf = anchorBox.zw * 0.5 * anchorAmount;
    float dAnchor = anchorAmount > 0.01 ? roundedBox(px - anchorBox.xy - anchorBox.zw * 0.5, anchorHalf, min(anchorRadius * anchorAmount, min(anchorHalf.x, anchorHalf.y))) : 1e5;

    float wobble = (0.9 * sin(px.x * 0.031 + seed) + 0.6 * sin(px.y * 0.047 + seed * 1.7)) * inkAmount;
    float d = smoothUnion(dPanel, dAnchor, blend) + wobble;
    float alpha = smoothstep(0.8, -0.8, d);

    // The same living sky as every card in ETEA
    float horizon = panelBox.y + panelBox.w * (1.0 - rise);
    float height = clamp((horizon - px.y) / max(panelBox.w, 1.0), 0.0, 1.0);
    vec3 color = mix(deep.rgb, mix(deep.rgb, tint.rgb, 0.3), exp(-height * 8.0));

    vec2 drift = vec2(time * 0.011, -time * 0.007);
    vec2 q = px / 170.0 + seed;
    float fold = cloud(q * 0.8 + drift);
    float gas = cloud(q + fold * 1.7 - drift * 0.6);
    color += tint.rgb * pow(gas, 3.0) * (0.3 + 0.6 * exp(-height * 5.0));

    vec2 cell = floor(px / 5.0);
    if (hash(cell + seed) > 0.984) {
        float pace = hash(cell * 1.7);
        float breath = 0.5 + 0.5 * sin(time * (0.5 + 1.8 * pace) + pace * 40.0);
        vec2 spot = fract(px / 5.0) - 0.5 + (vec2(hash(cell + 2.0), hash(cell + 5.0)) - 0.5) * 0.4;
        color += vec3(1.0, 0.96, 0.9) * smoothstep(0.34, 0.06, length(spot)) * (0.12 + breath * 0.5) * smoothstep(0.0, 0.2, height);
    }

    float far = horizon + 3.5 * hills(px.x, seed);
    float near = horizon + 8.0 + 3.5 * hills(px.x, seed + 2.4);
    color += tint.rgb * exp(-max(far - px.y, 0.0) / 18.0) * 0.3;
    color = mix(color, mix(deep.rgb, tint.rgb, 0.3) * 0.75, smoothstep(0.7, -0.7, far - px.y));
    color = mix(color, deep.rgb * 0.55, smoothstep(0.7, -0.7, near - px.y));

    // The ink outline, gone over twice like a pencil, once the panel has settled
    float line = (smoothstep(1.3, 0.3, abs(d)) * 0.72 + smoothstep(0.9, 0.2, abs(d + 2.2)) * 0.28) * inkAmount;
    color = mix(color, ink.rgb, line);
    alpha = max(alpha, line);

    color += (hash(floor(px)) - 0.5) * 0.028;
    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
