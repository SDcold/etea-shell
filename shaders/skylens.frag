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
    vec2 box; // where this effect sits on the screen: only the lens's own box is drawn
    vec2 boxSize;
    vec2 pictureSize;
    vec2 smallSize;
    vec2 center; // the window's middle, in pixels
    vec2 anchor; // the point of the sky shown at that middle
    float reach; // half its width, in pixels
    float exponent; // 0.62 is ETEA's star, 2 a disc, above that a porthole
    float aspect; // width over height
    float scale; // how small the sky is drawn inside it
    float painted; // 1 for a painted sky, 0 for a picture
    float smallReady; // the small copy may still be on its way: the full one stands in
    vec4 terrain0; // the hills of the world your sky makes, as its moon wears them
    vec4 terrain1;
    vec4 terrain2;
    vec4 terrain3;
    float hills; // how far they have risen: they sink as the lens leaves its moon
    float unit; // pixels per unit of a 1600 wide screen
    float rough;
    vec4 light; // its moon's ring and star, drawn as moon.frag draws them, fading as it leaves
    float ring;
    float starSize;
    float gap;
    float seed;
    float wobbly; // 0 for a porthole's steady line, 1 for a moon's
    float starLit;
    float grain;
};

layout(binding = 1) uniform sampler2D picture; // the background's own texture
layout(binding = 2) uniform sampler2D small; // the same picture, 512 wide and mipmapped

// terrain.frag's ridge, as moon.frag draws it
float ridge(float s, float a) {
    float fine = rough, middle = mix(0.45, 1.0, rough);
    return 0.5 * sin(7.0 * a + 0.3 + s)
        + 0.3 * sin(17.0 * a + 1.1 + s)
        + 0.22 * middle * sin(41.0 * a + 2.2 + s)
        + 0.16 * middle * sin(97.0 * a + 0.7 + s)
        + 0.11 * fine * sin(211.0 * a + 1.9 + s)
        + 0.07 * fine * sin(431.0 * a + 3.1 + s)
        + 0.05 * fine * sin(863.0 * a + 0.4 + s);
}

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec3 overlay(vec3 base, float n) {
    return mix(2.0 * base * n, 1.0 - 2.0 * (1.0 - base) * (1.0 - n), step(0.5, base));
}

// Your sky, exactly as the background draws it, seen through a window that folds from the
// whole screen into ETEA's star, then rounds into a porthole: |x|^e + |y|^e = r^e
void main() {
    vec2 p = box + qt_TexCoord0 * boxSize;
    vec2 d = abs(p - center) * vec2(1.0 / aspect, 1.0);
    float r = pow(pow(d.x, exponent) + pow(d.y, exponent), 1.0 / exponent);
    float h = reach / aspect;
    float slope = max(length(vec2(dFdx(r), dFdy(r))), 1e-4);
    float inside = clamp((h - r) / slope + 0.5, 0.0, 1.0);
    vec2 local = p - center;
    vec2 starAt = abs(local - vec2(0.0, -(h + 1.6)));
    float starShape = pow(pow(starAt.x, 0.62) + pow(starAt.y, 0.62), 1.0 / 0.62);
    float starSlope = max(length(vec2(dFdx(starShape), dFdy(starShape))), 1e-4);

    // The ring and star of the moon it came from, as moon.frag draws them
    vec4 ink = vec4(0.0);
    if (ring > 0.0) {
        float along = atan(local.x, -local.y) * h;
        float drift = (sin(along * 0.021 + seed) * 0.7 + sin(along * 0.047 + seed * 2.3) * 0.4 + sin(along * 0.11 + seed * 5.1) * 0.2) * wobbly;
        float line = clamp(0.65 + 0.5 - abs((r - (h + 1.6 + drift)) / slope), 0.0, 1.0) * 0.72;
        float echo = clamp(0.4 + 0.5 - abs((r - (h + drift)) / slope), 0.0, 1.0) * 0.72 * 0.38;
        float open = clamp(abs(local.x) - gap + 0.5, 0.0, 1.0);
        float a = max(line, echo) * mix(1.0, open, step(local.y, 0.0)) * ring;
        ink = vec4(light.rgb, 1.0) * a;
        float star = clamp((starSize - starShape) / starSlope + 0.5, 0.0, 1.0) * mix(0.55, 1.0, starLit) * ring;
        vec3 starColor = mix(vec3(0.847, 0.824, 0.831), vec3(1.0), starLit);
        ink = vec4(starColor, 1.0) * star + ink * (1.0 - star);
    }
    if (inside <= 0.0) {
        fragColor = ink * qt_Opacity;
        return;
    }

    // The point of the full-size sky this pixel shows
    vec2 s = ((p - center) / scale + anchor) / resolution;
    vec3 color;
    if (painted > 0.5) {
        float y = s.y;
        color = y < 0.62 ? mix(colorTop.rgb, colorMid.rgb, y / 0.62) : mix(colorMid.rgb, colorLow.rgb, min((y - 0.62) / 0.3, 1.0));
    } else {
        vec2 size = max(pictureSize, vec2(1.0));
        vec2 shown = size * max(resolution.x / size.x, resolution.y / size.y);
        vec2 uv = (s * resolution - (resolution - shown) * 0.5) / shown;
        // Both are cropped alike, so where they hand over nothing moves
        vec2 little = max(smallSize, vec2(1.0));
        vec2 shownSmall = little * max(resolution.x / little.x, resolution.y / little.y);
        vec2 uvSmall = (s * resolution - (resolution - shownSmall) * 0.5) / shownSmall;
        color = mix(texture(picture, uv).rgb, texture(small, uvSmall).rgb, smoothstep(0.5, 0.35, scale) * smallReady);
    }

    // The moon's hills, drawn as moon.frag does over the sky as shown, so the hand-over
    // between the two is seamless
    if (hills > 0.0) {
        float contentH = resolution.y * scale;
        vec2 middle = center + (resolution * 0.5 - anchor) * scale;
        float radius = contentH * 9.0;
        vec2 hub = vec2(middle.x, middle.y - contentH * 0.5 + contentH * 0.74 + radius + (1.0 - hills) * contentH * 0.4);
        float r = distance(p, hub);
        float angle = atan(p.x - hub.x, hub.y - p.y);
        float units = radius / unit;
        float amp = min(units * 0.024, 34.0) * 0.9 * unit;
        float sampleStep = 2.0 * min(3.14159, asin(min(1.0, 1152.0 / units)) * 1.15) / 340.0;
        vec4 tones[4] = vec4[](terrain0, terrain1, terrain2, terrain3);
        const float depth[4] = float[](0.0, 0.0065, 0.014, 0.023);
        const float lift[4] = float[](1.0, 0.8, 0.7, 0.55);
        for (int l = 0; l < 4; l++) {
            float cell = angle / sampleStep;
            float seedL = 1.2 + float(l) * 3.3;
            float shape = mix(ridge(seedL, floor(cell) * sampleStep), ridge(seedL, ceil(cell) * sampleStep), fract(cell));
            float edge = radius * (1.0 - depth[l]) + amp * lift[l] * shape;
            color = mix(color, tones[l].rgb, clamp(edge - r + 0.5, 0.0, 1.0));
        }
    }

    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));
    color = mix(color, overlay(color, n), grain) + (n - 0.5) * grain * 0.065 + painted * 0.011;
    vec4 sky = vec4(color, 1.0) * inside;
    fragColor = (ink + sky * (1.0 - ink.a)) * qt_Opacity;
}
