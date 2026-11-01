#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 layer0;
    vec4 layer1;
    vec4 layer2;
    vec4 layer3;
    vec2 resolution;
    float horizon;
    float relief;
    float curve;
    float planetAngle; // how far the planet has turned, for the page transition
    float grain;
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

// The ridgeline: finer and finer waves piled on top of each other
float ridge(float seed, float a) {
    return 0.5 * sin(7.0 * a + 0.3 + seed)
        + 0.3 * sin(17.0 * a + 1.1 + seed)
        + 0.22 * sin(41.0 * a + 2.2 + seed)
        + 0.16 * sin(97.0 * a + 0.7 + seed)
        + 0.11 * sin(211.0 * a + 1.9 + seed)
        + 0.07 * sin(431.0 * a + 3.1 + seed)
        + 0.05 * sin(863.0 * a + 0.4 + seed);
}

void main() {
    // Think in mockup units, 1600 wide, so the hills look the same everywhere
    float k = resolution.x / 1600.0;
    vec2 p = qt_TexCoord0 * resolution / k;
    float height = resolution.y / k;
    vec2 center = vec2(800.0, height * horizon + curve);
    float r = distance(p, center);
    float angle = atan(p.x - center.x, center.y - p.y);

    vec4 colors[4] = vec4[](layer0, layer1, layer2, layer3);
    float depth[4] = float[](0.0, 0.0065, 0.014, 0.023);
    float amp[4] = float[](1.0, 0.8, 0.7, 0.55);
    float maxAmp = min(curve * 0.024, 34.0) * relief;
    float sampleStep = 2.0 * min(3.14159, asin(min(1.0, 1152.0 / curve)) * 1.15) / 340.0;

    // Paint the hills from the farthest to the closest
    vec4 color = vec4(0.0);
    for (int l = 0; l < 4; l++) {
        float a = angle + planetAngle * (1.0 - float(l) * 0.012);
        // Reading the ridge in short segments is what gives it that jagged edge
        float cell = a / sampleStep;
        float seed = 1.2 + float(l) * 3.3;
        float shape = mix(ridge(seed, floor(cell) * sampleStep), ridge(seed, ceil(cell) * sampleStep), fract(cell));
        float edge = curve * (1.0 - depth[l]) + maxAmp * amp[l] * shape;
        float inside = smoothstep(edge + 0.6, edge - 0.6, r);
        color = mix(color, vec4(colors[l].rgb, 1.0), inside);
    }

    float n = mix(0.376, 0.627, hash(floor(qt_TexCoord0 * resolution)));
    vec3 rgb = mix(color.rgb, overlay(color.rgb, n), grain);
    fragColor = vec4(rgb * color.a, color.a) * qt_Opacity;
}
