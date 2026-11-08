#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 colorTop; // your sky's top colour, which the air steps away from
    vec4 night;
    vec2 resolution;
    vec2 center; // the planet's centre, in pixels
    float radius; // the planet's radius, in pixels
    float edge; // where the air ends: the belt, in pixels from the centre
    float grain;
    float drift; // the stars slide a little as the belt turns
};

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec3 overlay(vec3 base, float n) {
    return mix(2.0 * base * n, 1.0 - 2.0 * (1.0 - base) * (1.0 - n), step(0.5, base));
}

// Seen from the edge of the air: night with its stars, and your air in four flat bands
// round the planet, stepping from your sky's top colour toward night. Each band is a
// hard step, antialiased over one pixel, never a gradient.
void main() {
    vec2 p = qt_TexCoord0 * resolution;
    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));

    // Stars as small round dots, so they slide smoothly when the belt turns: one maybe in
    // each 3 px cell, at its own place inside it, looked for in the cells around
    vec2 q = (p + vec2(drift, 0.0)) / 3.0;
    float star = 0.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 cell = floor(q) + vec2(float(i), float(j));
            if (hash(cell + 3.7) < 0.9874)
                continue;
            vec2 spot = cell + 0.2 + 0.6 * vec2(hash(cell + 5.1), hash(cell + 8.3));
            float size = 0.55 + 0.45 * hash(cell + 2.9);
            float lit = clamp(size - distance(q, spot) * 3.0 + 0.5, 0.0, 1.0);
            star = max(star, lit * (0.35 + 0.65 * hash(cell + 11.0)));
        }
    }
    vec3 color = night.rgb + n * 0.012 + star;

    // The outermost band first, each nearer one laid over it
    float r = distance(p, center);
    float span = edge - radius;
    const float reach[4] = float[](1.0, 0.75, 0.5, 0.25);
    const float dark[4] = float[](0.82, 0.6, 0.38, 0.16);
    for (int i = 0; i < 4; i++) {
        float inside = clamp(radius + span * reach[i] - r + 0.5, 0.0, 1.0);
        vec3 band = mix(colorTop.rgb, night.rgb, dark[i]);
        band = mix(band, overlay(band, n), grain) + (n - 0.5) * grain * 0.065;
        color = mix(color, band, inside);
    }
    fragColor = vec4(color, 1.0) * qt_Opacity;
}
