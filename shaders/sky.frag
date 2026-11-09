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
    vec4 colorTopB;
    vec4 colorMidB;
    vec4 colorLowB;
    // A new day: inside an ellipse rising from under the horizon at the sun's place, 2.6
    // times as wide as tall, the colours are B; outside they stay as they were. An edge of
    // 0 changes nothing. Its rim is a line of the new light, three flat steps behind it on
    // the new side: inside for a dawn, outside for a dusk.
    vec2 dawnCenter;
    float dawnEdge;
    float bandInside;
    vec4 dawnLight;
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

// How far inside the new day a pixel is (0 or 1, antialiased), and the light on its rim
vec2 dawnAt(vec2 p) {
    float n = length(vec2((p.x - dawnCenter.x) / 2.6, p.y - dawnCenter.y));
    float slope = max(length(vec2(dFdx(n), dFdy(n))), 1e-4);
    if (dawnEdge <= 0.0)
        return vec2(0.0);
    float inside = clamp((dawnEdge - n) / slope + 0.5, 0.0, 1.0);
    float line = clamp(0.75 + 0.5 - abs(dawnEdge - n) / slope, 0.0, 1.0);
    float behind = bandInside > 0.5 ? dawnEdge - n : n - dawnEdge;
    float steps = behind > 0.0 ? ceil(clamp(1.0 - behind / 90.0, 0.0, 1.0) * 3.0) / 3.0 : 0.0;
    return vec2(inside, max(line, steps * 0.16));
}

// The sky gradient, then the grain on top
void main() {
    float y = qt_TexCoord0.y;
    vec2 day = dawnAt(qt_TexCoord0 * resolution);
    vec3 top = mix(colorTop.rgb, colorTopB.rgb, day.x), mid = mix(colorMid.rgb, colorMidB.rgb, day.x), low = mix(colorLow.rgb, colorLowB.rgb, day.x);
    vec3 color = y < 0.62 ? mix(top, mid, y / 0.62) : mix(mid, low, min((y - 0.62) / 0.3, 1.0));
    color = mix(color, dawnLight.rgb, day.y);

    // One grain per screen pixel, so it stays even with fractional scaling
    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));
    // The faint lift stays at zero grain, so the colours don't shift
    color = mix(color, overlay(color, n), grain) + 0.011 + (n - 0.5) * grain * 0.065;

    // Above the atmosphere the sky goes dark and the stars come out
    vec2 cell = floor(qt_TexCoord0 * resolution / 2.0);
    float star = step(0.9972, hash(cell + 3.7)) * (0.35 + 0.65 * hash(cell + 11.0));
    color = mix(color, vec3(0.02, 0.024, 0.05) + n * 0.012, space) + star * space;
    fragColor = vec4(color, 1.0) * qt_Opacity;
}
