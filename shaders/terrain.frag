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
    float orbit; // 0 on the ground, 1 once the ground has become a whole planet
    vec4 rimColor;
    vec4 l0;
    vec4 l1;
    vec4 l2;
    vec4 l3;
    vec4 l4;
    vec4 l5;
    vec4 l6;
    float music; // 0 in silence, 1 while the ground is dancing
    float lift; // how high the ridges can climb
    float bars; // 1 draws bars behind the ground, 0 draws contour lines
    float arrival; // 0 at rest, then from touching down on a new world to the end of it
    vec4 arrivalLight;
    float rough; // how jagged the crests are: long swells at 0, broken rock at 1
    float flatRim; // 1 at the edge of the air: a flat limb and a day side in flat steps
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

// The ridgeline: finer and finer waves piled on top of each other. A smooth world keeps
// the broad ones and lets the fine ones go.
float ridge(float seed, float a) {
    float fine = rough, middle = mix(0.45, 1.0, rough);
    return 0.5 * sin(7.0 * a + 0.3 + seed)
        + 0.3 * sin(17.0 * a + 1.1 + seed)
        + 0.22 * middle * sin(41.0 * a + 2.2 + seed)
        + 0.16 * middle * sin(97.0 * a + 0.7 + seed)
        + 0.11 * fine * sin(211.0 * a + 1.9 + seed)
        + 0.07 * fine * sin(431.0 * a + 3.1 + seed)
        + 0.05 * fine * sin(863.0 * a + 0.4 + seed);
}

float band(int i) {
    vec4 rows[7] = vec4[](l0, l1, l2, l3, l4, l5, l6);
    i = clamp(i, 0, 25);
    return rows[i / 4][i % 4];
}

// How loud a given note is
float sound(float t) {
    float at = clamp(t, 0.0, 1.0) * 25.0;
    int i = int(floor(at));
    float f = fract(at);
    f = f * f * (3.0 - 2.0 * f);
    return mix(band(i), band(i + 1), f);
}

// Soft random blobs, stacked at a few sizes, for the landmasses
float blob(vec2 p) {
    vec2 i = floor(p), f = fract(p);
    f = f * f * (3.0 - 2.0 * f);
    float a = hash(i), b = hash(i + vec2(1.0, 0.0)), c = hash(i + vec2(0.0, 1.0)), d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float land(vec2 p) {
    return blob(p) * 0.55 + blob(p * 2.3 + 4.1) * 0.3 + blob(p * 5.1 + 9.7) * 0.15;
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
    float maxAmp = min(curve * 0.024, 34.0) * relief * (1.0 - orbit);
    float dance = music * (1.0 - orbit);

    // Most of the screen is sky, so skip all the work up there
    if (orbit < 0.001 && r > curve + maxAmp + 72.0 + dance * lift * 1.6) {
        fragColor = vec4(0.0);
        return;
    }

    float sampleStep = 2.0 * min(3.14159, asin(min(1.0, 1152.0 / curve)) * 1.15) / 340.0;

    // The mountains never move. The music lives in fine contour lines echoing the ridge,
    // like a seismograph drawn over the landscape. They stay in order and never cross:
    // the louder it gets, the further they spread apart, and each softens as it climbs.
    vec4 color = vec4(0.0);
    if (dance > 0.001 && bars > 0.5) {
        // The other style: plain bars standing behind the hills, rounded at the top
        float count = 58.0;
        float cell = floor(p.x / 1600.0 * count);
        float wide = 1600.0 / count;
        float offset = abs(p.x - (cell + 0.5) * wide);
        float t = 0.5 - 0.5 * cos(3.14159 * ((cell + 0.5) / count * 1.3 + 0.17));
        float heard = (sound(t - 0.03) + sound(t) * 2.0 + sound(t + 0.03)) * 0.25;
        heard = 1.0 - exp(-heard * (0.55 + 0.75 * t) * 1.9);
        float half_ = wide * 0.3;
        float top = curve + maxAmp + 2.0 + heard * lift * 1.5;
        float above = max(r - (top - half_), 0.0);
        float shape = smoothstep(half_ + 0.7, half_ - 0.7, length(vec2(offset, above)));
        float rise = clamp((r - curve) / (lift * 1.5), 0.0, 1.0);
        color = vec4(mix(rimColor.rgb, vec3(1.0, 0.97, 0.92), rise * 0.75), shape * (0.55 + 0.4 * rise) * dance);
    } else if (dance > 0.001) {
        float ridgeCell = (angle + planetAngle) / sampleStep;
        float ridgeShape = mix(ridge(1.2, floor(ridgeCell) * sampleStep), ridge(1.2, ceil(ridgeCell) * sampleStep), fract(ridgeCell));
        float glow = 0.0;
        for (int i = 0; i < 6; i++) {
            float step = float(i);
            float t = 0.5 - 0.5 * cos(3.14159 * (p.x / 1600.0 * 1.3 + 0.17 + step * 0.012));
            float heard = (sound(t - 0.05) + sound(t) * 2.0 + sound(t + 0.05)) * 0.25;
            heard = 1.0 - exp(-heard * (0.55 + 0.75 * t) * 1.9);
            float line = curve + maxAmp * ridgeShape * (1.0 - step * 0.14) + (step + 1.0) * (5.0 + heard * lift / 6.0);
            glow += exp(-abs(r - line) / 0.8) * (1.0 - step / 6.5) * (0.22 + heard * 0.8);
        }
        float light = clamp(glow * dance, 0.0, 1.0);
        color = vec4(mix(rimColor.rgb, vec3(1.0, 0.97, 0.92), 0.7), light);
    }

    // Touching down: light runs out along the ridges from where we landed, and fades
    // behind itself in three flat steps, never a blur
    float shine = 0.0;
    if (arrival > 0.0) {
        float run = clamp(arrival / 0.42, 0.0, 1.0);
        float front = (1.0 - (1.0 - run) * (1.0 - run)) * 980.0;
        float behind = front - abs(angle) * curve;
        float lit = behind < 0.0 ? 0.0 : clamp(1.0 - behind / 300.0, 0.0, 1.0);
        shine = ceil(lit * 3.0) / 3.0 * (1.0 - smoothstep(0.42, 0.7, arrival)) * (1.0 - orbit);
    }

    // Paint the hills from the farthest to the closest
    for (int l = 0; l < 4; l++) {
        float a = angle + planetAngle * (1.0 - float(l) * 0.012);
        // Reading the ridge in short segments is what gives it that jagged edge
        float cell = a / sampleStep;
        float seed = 1.2 + float(l) * 3.3;
        float shape = mix(ridge(seed, floor(cell) * sampleStep), ridge(seed, ceil(cell) * sampleStep), fract(cell));
        float edge = curve * (1.0 - depth[l]) + maxAmp * amp[l] * shape;

        float inside = smoothstep(edge + 0.6, edge - 0.6, r);
        // The crest catches the light, the slope below barely any
        float crest = smoothstep(edge - 2.8, edge - 1.6, r);
        vec3 tone = mix(colors[l].rgb, arrivalLight.rgb, shine * mix(0.05, 0.95, crest));
        color = mix(color, vec4(tone, 1.0), inside);
    }

    // From space it's a real planet: continents, a day side and a night side, and a
    // thin glow of atmosphere catching the light around the edge
    vec3 sun = normalize(vec3(-0.55, -0.6, 0.58));
    vec2 q = (p - center) / curve;
    float edgeDistance = length(q);
    vec4 rim = vec4(0.0);
    if (orbit > 0.001) {
        // Worked out for every pixel, so its slope across a pixel is known everywhere
        float depthZ = sqrt(max(0.0, 1.0 - edgeDistance * edgeDistance));
        vec3 normal = vec3(q, depthZ);
        float facing = dot(normal, sun);
        float aa = max(fwidth(facing), 1e-4);
        if (edgeDistance < 1.0 + 2.0 / curve) {
            vec2 surface = vec2(atan(q.x, depthZ) + planetAngle, asin(clamp(q.y, -1.0, 1.0))) * 2.6;
            float ground = land(surface + 1.7);
            vec3 tone = mix(layer3.rgb, layer2.rgb, smoothstep(0.34, 0.42, ground));
            tone = mix(tone, layer1.rgb, smoothstep(0.44, 0.52, ground));
            tone = mix(tone, layer0.rgb, smoothstep(0.54, 0.62, ground));
            vec3 lit = tone * mix(0.1, 1.0, smoothstep(-0.12, 0.65, facing));
            if (flatRim > 0.5) {
                // Night comes in two hard steps, like a paper cut-out
                float dusk = clamp((0.25 - facing) / aa + 0.5, 0.0, 1.0);
                float dark = clamp((-0.1 - facing) / aa + 0.5, 0.0, 1.0);
                lit = tone * (1.0 - 0.42 * dusk) * (1.0 - 0.5 * dark);
            }
            float solid = smoothstep(1.0, 1.0 - 2.0 / curve, edgeDistance);
            // Under a flat limb the disc runs a pixel past the edge, so the ring's soft inner
            // pixel lies on solid ground and nothing shows through between them
            if (flatRim > 0.5)
                solid = clamp((1.0 - edgeDistance) * curve * k + 1.5, 0.0, 1.0);
            color = mix(color, vec4(lit, 1.0), orbit * solid);
        }
        if (flatRim > 0.5) {
            // The limb: a flat ring of your low sky colour, three units wide
            float out_ = (edgeDistance - 1.0) * curve * k;
            float ring = clamp(out_ + 0.5, 0.0, 1.0) * clamp(3.0 * k - out_ + 0.5, 0.0, 1.0) * orbit;
            rim = vec4(rimColor.rgb * ring, ring);
        } else {
            float side = 0.25 + 0.75 * max(0.0, dot(normalize(q), normalize(sun.xy)));
            float glow = exp(-abs(edgeDistance - 1.0) * 26.0) * side * orbit;
            rim = vec4(rimColor.rgb * glow, glow);
        }
    }

    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy))); // per screen pixel, like the sky
    vec3 rgb = mix(color.rgb, overlay(color.rgb, n), grain);
    vec4 result = vec4(rgb * color.a, color.a);
    vec4 lit = flatRim > 0.5 ? rim + result * (1.0 - rim.a) : result + rim * (1.0 - result.a * 0.35);
    fragColor = lit * qt_Opacity;
}
