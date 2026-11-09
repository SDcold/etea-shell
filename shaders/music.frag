#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 l0; // what cava hears, 26 bands, four to a vector
    vec4 l1;
    vec4 l2;
    vec4 l3;
    vec4 l4;
    vec4 l5;
    vec4 l6;
    vec4 ink; // the music's colour
    vec4 light; // and the light its tops catch
    vec2 world; // the whole world's size, in pixels
    vec2 origin; // where this strip starts in it
    vec2 size; // and its size
    float horizon;
    float curve; // the planet's radius, in units of a 1600 wide world
    float relief;
    float orbit;
    float planetAngle;
    float seed;
    float farA; // the far ground's form, which the lines echo
    float rough;
    float hills; // 1 with hills: the music stands behind them; 0 on the screen's edge
    float style; // 0 lines, 1 bars, 2 stars
    float reach; // how high it climbs, in units
    float density; // how many columns across the screen
    float time; // seconds, for the stars to breathe and their sparks to rise
};

// The ridge and its forms, as terrain.frag draws them, for the lines to follow
float ridge(float s, float a) {
    float fine = rough, middle = mix(0.45, 1.0, rough);
    return 0.5 * sin(7.0 * a + 0.3 + s) + 0.3 * sin(17.0 * a + 1.1 + s)
        + 0.22 * middle * sin(41.0 * a + 2.2 + s) + 0.16 * middle * sin(97.0 * a + 0.7 + s)
        + 0.11 * fine * sin(211.0 * a + 1.9 + s) + 0.07 * fine * sin(431.0 * a + 3.1 + s)
        + 0.05 * fine * sin(863.0 * a + 0.4 + s);
}

float tables(float s, float a) {
    float swell = 0.45 * sin(13.0 * a + 0.3 + s) + 0.35 * sin(31.0 * a + 1.1 + s) + 0.2 * sin(67.0 * a + 2.2 + s);
    float x = swell * 2.2 + 2.2;
    return (floor(x) + smoothstep(0.84, 0.97, fract(x))) / 2.2 - 1.0 + 0.035 * rough * sin(431.0 * a + 3.1 + s);
}

float dunes(float s, float a) {
    float x = a * 17.0 + 0.6 * sin(9.0 * a + s) + s;
    float f = fract(x);
    float face = f < 0.8 ? f / 0.8 : (1.0 - f) / 0.2;
    return 0.35 * sin(4.0 * a + 0.7 + s) + (face - 0.5) * 1.1;
}

float form(float kind, float s, float a) {
    return kind < 0.5 ? ridge(s, a) : kind < 1.5 ? tables(s, a) : dunes(s, a);
}

float heightOf(float kind, float s, float a, float sampleStep) {
    float cell = a / sampleStep;
    return mix(form(kind, s, floor(cell) * sampleStep), form(kind, s, ceil(cell) * sampleStep), fract(cell));
}

float band(int i) {
    vec4 rows[7] = vec4[](l0, l1, l2, l3, l4, l5, l6);
    i = clamp(i, 0, 25);
    return rows[i / 4][i % 4];
}

// How loud a note is, low notes on the left
float sound(float t) {
    float at = clamp(t, 0.0, 1.0) * 25.0;
    int i = int(floor(at));
    float f = fract(at);
    f = f * f * (3.0 - 2.0 * f);
    return mix(band(i), band(i + 1), f);
}

// What a column across the screen hears, softened toward its neighbours and with the
// quiet highs lifted a little, 0 to 1
float heardAt(float x) {
    float t = 0.5 - 0.5 * cos(3.14159 * (x / 1600.0 * 1.3 + 0.17));
    float heard = (sound(t - 0.03) + sound(t) * 2.0 + sound(t + 0.03)) * 0.25;
    return 1.0 - exp(-heard * (0.55 + 0.75 * t) * 1.9);
}

// What a star hears: its own note across the whole range, low on the left, lightly
// smoothed so each star moves on its own, the quiet highs lifted
float noteAt(float x) {
    float t = 0.02 + 0.92 * clamp(x / 1600.0, 0.0, 1.0);
    float heard = (sound(t - 0.015) + sound(t) * 2.0 + sound(t + 0.015)) * 0.25 * mix(1.0, 1.7, t);
    return clamp(pow(heard, 0.85), 0.0, 1.0);
}

// ETEA's star as a distance: |x|^0.62 + |y|^0.62 = r^0.62
float starShape(vec2 p) {
    vec2 a = abs(p);
    return pow(pow(a.x, 0.62) + pow(a.y, 0.62), 1.0 / 0.62);
}

float hash(float n) {
    return fract(sin(n * 127.1) * 43758.5453);
}

// Over: a colour laid on what's below it
vec4 over(vec4 top, vec4 below) {
    return top + below * (1.0 - top.a);
}

// Distance from a point to a segment
float toSegment(vec2 p, vec2 a, vec2 b) {
    vec2 ab = b - a;
    float t = clamp(dot(p - a, ab) / max(dot(ab, ab), 1e-4), 0.0, 1.0);
    return length(p - a - ab * t);
}

// The music on the ground, drawn only in the strip it can reach: lines echoing the
// ridge like a seismograph, bars, or columns of stars joined top to top. Flat, each edge
// antialiased over one pixel.
void main() {
    float k = world.x / 1600.0;
    vec2 p = (origin + qt_TexCoord0 * size) / k; // in units of the whole world
    float height = world.y / k;
    vec2 center = vec2(800.0, height * horizon + curve);
    float r = distance(p, center);
    float maxAmp = min(curve * 0.024, 34.0) * relief * (1.0 - orbit);
    // How far above its floor: the ridge's foot with hills, the screen's edge without,
    // measured straight up there so it stands out to the corners
    float up = mix(height - p.y, r - (curve + maxAmp), hills);
    float px = 1.0 / k; // a pixel, in units
    vec4 color = vec4(0.0);

    if (style < 0.5) {
        float angle = atan(p.x - center.x, center.y - p.y);
        float sampleStep = 2.0 * min(3.14159, asin(min(1.0, 1152.0 / curve)) * 1.15) / 340.0;
        float ridgeShape = hills > 0.5 ? heightOf(farA, seed, angle + planetAngle, sampleStep) : 0.0;
        float lit = 0.0;
        for (int i = 0; i < 6; i++) {
            float step = float(i);
            float heard = heardAt(p.x + step * 19.2);
            float line = (step + 1.0) * (5.0 + heard * reach / 9.0) + (hills > 0.5 ? curve + maxAmp * ridgeShape * (1.0 - step * 0.14) : 0.0);
            float d = abs((hills > 0.5 ? r : up) - line) / px;
            lit = max(lit, clamp(0.9 - d + 0.5, 0.0, 1.0) * (1.0 - step / 6.5) * (0.3 + heard * 0.7));
        }
        color = vec4(mix(ink.rgb, light.rgb, 0.5), 1.0) * lit;
    } else if (style < 1.5) {
        // Bars, rounded at the top, lighter as they climb
        float wide = 1600.0 / density;
        float cell = floor(p.x / wide);
        float offset = abs(p.x - (cell + 0.5) * wide);
        float heard = heardAt((cell + 0.5) * wide);
        float half_ = wide * 0.3;
        float top = 2.0 + heard * reach;
        float above = max(up - (top - half_), 0.0);
        float shape = clamp((half_ - length(vec2(offset, above))) / px + 0.5, 0.0, 1.0);
        float rise = clamp(up / reach, 0.0, 1.0);
        color = vec4(mix(ink.rgb, light.rgb, rise * 0.75), 1.0) * shape * (0.55 + 0.4 * rise);
    } else {
        // A constellation that breathes with the music: one star per band of what's heard,
        // riding on it and growing with it, whiter the louder; on a loud note it throws out
        // its four rays; a thread of ink joins it to the next. Each pixel reads three bands
        // at most, so it moves as smoothly as the bars.
        vec4 rows[7] = vec4[](l0, l1, l2, l3, l4, l5, l6);
        float wide = 1600.0 / 26.0;
        float cell = clamp(floor(p.x / wide), 0.0, 25.0);
        float lift = reach * 1.3;
        vec2 at = vec2(p.x, up);
        float heights[3];
        float louds[3];
        for (int n = 0; n < 3; n++) {
            float c = clamp(cell + float(n - 1), 0.0, 25.0);
            int i = int(c);
            float b = rows[i / 4][i % 4];
            float heard = 1.0 - exp(-b * 1.9 * (0.6 + 0.7 * c / 25.0));
            louds[n] = heard;
            heights[n] = 10.0 + heard * lift;
        }
        vec2 here = vec2((cell + 0.5) * wide, heights[1]);
        // The threads to either side
        float d = min(cell > 0.0 ? toSegment(at, vec2(here.x - wide, heights[0]), here) : 1e4, cell < 25.0 ? toSegment(at, here, vec2(here.x + wide, heights[2])) : 1e4) / px;
        vec4 thread = vec4(ink.rgb, 1.0) * clamp(0.45 - d + 0.5, 0.0, 1.0) * (0.35 + 0.4 * louds[1]);

        float heard = louds[1];
        float seedC = hash(cell + 17.0);
        float breath = 1.0 + 0.12 * sin(time * (1.4 + seedC) + seedC * 6.283);
        float size_ = (3.2 + 11.0 * heard) * breath;
        vec2 q = abs(at - here);
        // ETEA's star, near enough with square roots, and cheap: (√|x| + √|y|)² = r
        float shape = sqrt(q.x) + sqrt(q.y);
        shape *= shape;
        float body = clamp((size_ - shape) / (1.5 * px) + 0.5, 0.0, 1.0);
        vec3 tone = mix(ink.rgb, light.rgb, smoothstep(0.2, 0.8, heard));
        vec4 star = vec4(tone, 1.0) * body * (0.5 + 0.5 * heard);
        // Its rays on a loud note, in two flat steps, kept within its own column
        float flare = smoothstep(0.4, 0.9, heard);
        float len = min(size_ * (1.2 + 2.4 * flare), wide * 0.48);
        float w = 0.5 * px + 0.03 * size_;
        vec2 thin = clamp((w - q.yx) / px + 0.5, 0.0, 1.0);
        vec2 inner = clamp((len * 0.5 - q) / px + 0.5, 0.0, 1.0);
        vec2 outer = clamp((len - q) / px + 0.5, 0.0, 1.0);
        vec2 rays = thin * (0.25 * outer + 0.3 * inner);
        star = over(star, vec4(light.rgb, 1.0) * min(rays.x + rays.y, 0.55) * flare);
        color = over(star, thread);
    }
    fragColor = color * qt_Opacity;
}
