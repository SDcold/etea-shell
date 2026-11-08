#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 skyTop; // a painted sky's colours, for the world's own sky
    vec4 skyMid;
    vec4 skyLow;
    vec4 terrain0; // the hills its picture would give, back to front
    vec4 terrain1;
    vec4 terrain2;
    vec4 terrain3;
    vec4 light; // the ink of its ring, in that picture's own light
    vec4 dominant; // its colour while it is still a star, loading
    vec4 night;
    vec2 size; // this effect, in pixels
    vec2 pictureSize;
    float halfHeight; // the moon's half height, in pixels
    float aspect; // 1 for a disc, the screen's for a porthole
    float exponent; // 2 for a disc, 4.6 for a porthole
    float ready; // 0 while its picture is on its way: a flat star, rounding into its moon
    float rise; // how far its hills have risen
    float kind; // 0 a picture, 1 a painted sky, 2 the way out to another folder
    float porthole; // 0 on the belt, 1 at the zenith: the ink loses its wobble
    float screenAspect; // the screen's width over its height, for the crop
    float unit; // pixels per unit of a 1600 wide screen
    float rough; // how jagged your world's ridge is
    float gap; // half the width of the break in the ring, under the star
    float seed;
    float grain;
    float inked; // how much of its ring and star are drawn
    float starSize; // the star on top of its ring, in pixels
    float starLit; // 0 asleep, 1 lit
};

layout(binding = 1) uniform sampler2D picture;

float hash(vec2 p) {
    vec3 q = fract(vec3(p.xyx) * 0.1031);
    q += dot(q, q.yzx + 33.33);
    return fract((q.x + q.y) * q.z);
}

vec3 overlay(vec3 base, float n) {
    return mix(2.0 * base * n, 1.0 - 2.0 * (1.0 - base) * (1.0 - n), step(0.5, base));
}

// terrain.frag's ridge, so a moon's hills are cut like your world's
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

// The superellipse |x/aspect|^e + |y|^e = r^e, as a distance in pixels to the level r
float norm(vec2 p, float e, float a) {
    vec2 d = abs(p) * vec2(1.0 / a, 1.0);
    return pow(pow(d.x, e) + pow(d.y, e), 1.0 / e);
}

// A hand never holds a line quite still: HandCard's wobble, along the ring
float wobble(float along) {
    return sin(along * 0.021 + seed) * 0.7 + sin(along * 0.047 + seed * 2.3) * 0.4 + sin(along * 0.11 + seed * 5.1) * 0.2;
}

void main() {
    vec2 p = (qt_TexCoord0 - 0.5) * size;

    // Loading, it's ETEA's star in its cached colour; it rounds into its moon as it lands
    float settle = 1.0 - pow(1.0 - ready, 3.0);
    float e = mix(0.62, exponent, settle);
    float h = halfHeight * mix(0.5, 1.0, settle);
    float f = norm(p, e, aspect);
    float slope = max(length(vec2(dFdx(f), dFdy(f))), 1e-4);
    float starShape = norm(p - vec2(0.0, -(h + 1.6)), 0.62, 1.0);
    float starSlope = max(length(vec2(dFdx(starShape), dFdy(starShape))), 1e-4);
    float inside = clamp((h - f) / slope + 0.5, 0.0, 1.0);

    // What the moon shows: the sky the screen would show, cropped as the screen crops it
    float contentH = 2.0 * h;
    vec2 content = vec2(max(contentH * screenAspect, contentH * aspect), contentH);
    vec2 s = p / content + 0.5;
    vec3 color = dominant.rgb;
    if (kind < 0.5) {
        vec2 natural = max(pictureSize, vec2(1.0));
        vec2 shown = natural * max(content.x / natural.x, content.y / natural.y);
        vec2 uv = (s * content - (content - shown) * 0.5) / shown;
        color = texture(picture, uv).rgb;
    } else if (kind < 1.5) {
        color = s.y < 0.62 ? mix(skyTop.rgb, skyMid.rgb, s.y / 0.62) : mix(skyMid.rgb, skyLow.rgb, min((s.y - 0.62) / 0.3, 1.0));
    } else {
        color = night.rgb;
    }

    // The hills it would give: four flat bands on your world's ridge, from a great circle
    // below, back to front. Read in short straight segments, like the ground itself.
    if (kind < 1.5 && rise > 0.0) {
        float radius = contentH * 9.0;
        vec2 center = vec2(0.0, -h + contentH * 0.74 + radius + (1.0 - rise) * contentH * 0.4);
        float r = distance(p, center);
        float angle = atan(p.x, center.y - p.y);
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
    color = mix(dominant.rgb, color, ready);

    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));
    color = mix(color, overlay(color, n), grain) + (n - 0.5) * grain * 0.065;
    vec4 result = vec4(color, 1.0) * inside * (kind > 1.5 ? 0.7 : 1.0);

    // Its ring, in its own light, with a fainter echo just inside, broken under its star
    float along = atan(p.x, -p.y) * h;
    float drift = wobble(along) * (1.0 - porthole);
    float ringAt = (f - (h + 1.6 + drift)) / slope;
    float echoAt = (f - (h + drift)) / slope;
    float line = clamp(0.65 + 0.5 - abs(ringAt), 0.0, 1.0) * 0.72;
    float echo = clamp(0.4 + 0.5 - abs(echoAt), 0.0, 1.0) * 0.72 * 0.38;
    // The way out is drawn with a dashed ring instead: dashes of 5, gaps of 7
    if (kind > 1.5) {
        line = step(fract(along / 12.0), 5.0 / 12.0) * clamp(0.75 + 0.5 - abs(ringAt), 0.0, 1.0) * 0.75;
        echo = 0.0;
    }
    float open = clamp(abs(p.x) - gap + 0.5, 0.0, 1.0);
    float ink = max(line, echo) * mix(1.0, open, step(p.y, 0.0)) * ready * inked;
    result = vec4(light.rgb, 1.0) * ink + result * (1.0 - ink);

    // Its star, on the ring at the top: ETEA's four points, |x|^0.62 + |y|^0.62 = r^0.62
    float star = clamp((starSize - starShape) / starSlope + 0.5, 0.0, 1.0) * mix(0.55, 1.0, starLit) * ready * inked;
    vec3 starColor = mix(vec3(0.847, 0.824, 0.831), vec3(1.0), starLit);
    result = vec4(starColor, 1.0) * star + result * (1.0 - star);

    fragColor = result * qt_Opacity;
}
