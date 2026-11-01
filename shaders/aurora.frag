#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 l0;
    vec4 l1;
    vec4 l2;
    vec4 l3;
    vec4 l4;
    vec4 l5;
    vec4 l6;
    vec4 tint;
    vec4 base;
    vec2 resolution;
    float time;
    float presence;
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

float band(int i) {
    vec4 rows[7] = vec4[](l0, l1, l2, l3, l4, l5, l6);
    i = clamp(i, 0, 25);
    return rows[i / 4][i % 4];
}

// The bass sits in the middle of the screen, higher notes spread out to the sides
float level(float t) {
    float at = t * 25.0;
    int i = int(floor(at));
    float f = fract(at);
    f = f * f * (3.0 - 2.0 * f);
    return mix(band(i), band(i + 1), f);
}

// Music rising behind the hills as an aurora, with stars riding its crest
void main() {
    vec2 uv = qt_TexCoord0;
    float t = abs(uv.x * 2.0 - 1.0);
    float up = 1.0 - uv.y;

    float soft = (level(t - 0.02) + level(t) * 2.0 + level(t + 0.02)) / 4.0;
    float crest = (0.2 + soft * 0.62) * (1.0 - smoothstep(0.75, 1.0, t) * 0.5);

    // Curtains of light hanging from the crest, drifting slowly sideways
    float curtain = noise(vec2(uv.x * 42.0 + time * 0.35, time * 0.22)) * 0.6 + noise(vec2(uv.x * 110.0 - time * 0.5, up * 3.0)) * 0.4;
    float inside = smoothstep(crest + 0.012, crest - 0.012, up);
    float climb = clamp(up / max(crest, 0.001), 0.0, 1.0);

    vec3 color = mix(base.rgb, tint.rgb, pow(climb, 2.2));
    float body = inside * (0.6 + 0.4 * curtain) * mix(0.96, 0.82, climb);

    // A bright thread along the top
    float pixelsAway = abs(up - crest) * resolution.y;
    float thread = exp(-pixelsAway / 1.8);
    float halo = exp(-max(up - crest, 0.0) * resolution.y / 22.0) * (1.0 - inside) * 0.3;

    color = mix(color, vec3(1.0, 0.97, 0.9), thread);
    float alpha = clamp(body + thread + halo, 0.0, 1.0);

    // A little star on each note
    float note = t * 25.0;
    float nearest = floor(note + 0.5) / 25.0;
    float height = (0.2 + band(int(floor(note + 0.5))) * 0.62) * (1.0 - smoothstep(0.75, 1.0, t) * 0.5);
    vec2 gap = vec2((t - nearest) * resolution.x * 0.5, (up - height) * resolution.y);
    float size = 2.0 + band(int(floor(note + 0.5))) * 7.0;
    float star = smoothstep(1.0, 0.0, pow(abs(gap.x) / size, 0.6) + pow(abs(gap.y) / size, 0.6));
    color = mix(color, vec3(1.0), star);
    alpha = max(alpha, star);

    float sides = smoothstep(1.0, 0.86, t);
    alpha *= sides * presence;
    fragColor = vec4(color * alpha, alpha) * qt_Opacity;
}
