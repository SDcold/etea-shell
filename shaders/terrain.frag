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
    // A sky being tried on: its colours sweep over the planet as ETEA's star, led by a
    // line of its light. A reach of 0 sweeps nothing.
    vec4 next0;
    vec4 next1;
    vec4 next2;
    vec4 next3;
    vec4 nextRim;
    vec4 sweepLight;
    vec2 sweepCenter;
    float sweepReach;
    // A new day, as in sky.frag: inside the ellipse the hills wear B, and its rim of light
    // runs over the crests in three flat steps, the touchdown's light
    vec4 layerB0;
    vec4 layerB1;
    vec4 layerB2;
    vec4 layerB3;
    vec4 rimB;
    vec2 dawnCenter;
    float dawnEdge;
    float bandInside;
    vec4 dawnLight;
    // Relief: the far ground (the two back layers) and the near one (the two front) each
    // take a form: 0 ridges, 1 tables, 2 dunes. A re-form runs B in from reformAt, along the
    // ground both ways, the far range first: the old silhouette dips and the new one rises
    // through it. seed moves the ridges and the continents.
    float seed;
    float farA;
    float nearA;
    float farB;
    float nearB;
    float seedB;
    float reformAt; // the angle it starts from, as seen on screen
    float reformFront; // how far the front has run, in units; below 0 nothing re-forms
    float sink; // 0 standing, 1 sunk past the bottom of the screen
    // The sun, never drawn: 0 to 1 along a low arc from left to right. It lights the day
    // side from orbit, and with cut on, the faces turned to it are one flat step brighter.
    float sunAt;
    float cut;
};

// Tables: the swell cut into flat tops and short steep cliffs, a little grit on the tops
float tables(float s, float a) {
    float swell = 0.45 * sin(13.0 * a + 0.3 + s) + 0.35 * sin(31.0 * a + 1.1 + s) + 0.2 * sin(67.0 * a + 2.2 + s);
    float x = swell * 2.2 + 2.2;
    float h = (floor(x) + smoothstep(0.84, 0.97, fract(x))) / 2.2 - 1.0;
    return h + 0.035 * rough * sin(431.0 * a + 3.1 + s);
}

// Dunes: long slopes up the wind and short slip faces down it, on a gentle swell
float dunes(float s, float a) {
    float x = a * 17.0 + 0.6 * sin(9.0 * a + s) + s;
    float f = fract(x);
    float face = f < 0.8 ? f / 0.8 : (1.0 - f) / 0.2;
    return 0.35 * sin(4.0 * a + 0.7 + s) + (face - 0.5) * 1.1;
}

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

float form(float kind, float s, float a) {
    return kind < 0.5 ? ridge(s, a) : kind < 1.5 ? tables(s, a) : dunes(s, a);
}

// A layer's height at an angle: read in short straight segments, which is what gives the
// ground its jagged edge
float heightOf(float kind, float s, float a, float sampleStep) {
    float cell = a / sampleStep;
    return mix(form(kind, s, floor(cell) * sampleStep), form(kind, s, ceil(cell) * sampleStep), fract(cell));
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

    vec2 sweepAt = abs(qt_TexCoord0 * resolution - sweepCenter);
    float sweepShape = pow(pow(sweepAt.x, 0.62) + pow(sweepAt.y, 0.62), 1.0 / 0.62);
    float sweepSlope = max(length(vec2(dFdx(sweepShape), dFdy(sweepShape))), 1e-4);
    float swept = sweepReach > 0.0 ? clamp((sweepReach - sweepShape) / sweepSlope + 0.5, 0.0, 1.0) : 0.0;
    vec2 pixel = qt_TexCoord0 * resolution;
    float dawnN = length(vec2((pixel.x - dawnCenter.x) / 2.6, pixel.y - dawnCenter.y));
    float dawnSlope = max(length(vec2(dFdx(dawnN), dFdy(dawnN))), 1e-4);
    float day = dawnEdge > 0.0 ? clamp((dawnEdge - dawnN) / dawnSlope + 0.5, 0.0, 1.0) : 0.0;
    float dayBehind = bandInside > 0.5 ? dawnEdge - dawnN : dawnN - dawnEdge;
    float dayLight = dawnEdge > 0.0 && dayBehind > 0.0 ? ceil(clamp(1.0 - dayBehind / 90.0, 0.0, 1.0) * 3.0) / 3.0 : 0.0;
    float dayLine = dawnEdge > 0.0 ? clamp(0.75 + 0.5 - abs(dawnEdge - dawnN) / dawnSlope, 0.0, 1.0) : 0.0;
    vec4 tone0 = mix(mix(layer0, layerB0, day), next0, swept), tone1 = mix(mix(layer1, layerB1, day), next1, swept);
    vec4 tone2 = mix(mix(layer2, layerB2, day), next2, swept), tone3 = mix(mix(layer3, layerB3, day), next3, swept);
    vec4 rimTone = mix(mix(rimColor, rimB, day), nextRim, swept);
    vec4 colors[4] = vec4[](tone0, tone1, tone2, tone3);
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
        float ridgeShape = heightOf(farA, seed, angle + planetAngle, sampleStep);
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

    // Sinking, the land drops past the bottom of the screen
    float push = sink * (resolution.y / k * (1.0 - horizon) + maxAmp * 1.6 + 8.0);

    // Paint the hills from the farthest to the closest
    for (int l = 0; l < 4; l++) {
        float a = angle + planetAngle * (1.0 - float(l) * 0.012);
        bool far_ = l < 2;
        float layerSeed = seed + float(l) * 3.3;
        float shape = heightOf(far_ ? farA : nearA, layerSeed, a, sampleStep);
        if (reformFront >= 0.0) {
            // The front runs both ways from where it started, each nearer layer a little behind
            float t = clamp((reformFront - float(l) * 80.0 - abs(angle - reformAt) * curve) / 300.0, 0.0, 1.0);
            if (t > 0.0) {
                float next = heightOf(far_ ? farB : nearB, seedB + float(l) * 3.3, a, sampleStep);
                float dip = sin(3.14159 * t);
                shape = mix(shape, next, t) * (1.0 - 0.35 * dip * dip);
            }
            // Its crests catch the touchdown's light just behind it, in three flat steps
            float behind = reformFront - float(l) * 80.0 - abs(angle - reformAt) * curve;
            float lit = behind < 0.0 ? 0.0 : clamp(1.0 - behind / 300.0, 0.0, 1.0);
            shine = max(shine, ceil(lit * 3.0) / 3.0 * (1.0 - orbit));
        }
        float edge = curve * (1.0 - depth[l]) + maxAmp * amp[l] * shape - push;

        float inside = smoothstep(edge + 0.6, edge - 0.6, r);
        // The crest catches the light, the slope below barely any
        float crest = smoothstep(edge - 2.8, edge - 1.6, r);
        vec3 tone = colors[l].rgb;
        // Cut faces: from the pixel, go up toward the sun along a steep line until the crest.
        // The face it comes out on says the light: one going down toward the sun faces it
        // and is a step lighter. Each face is so bounded by straight lines running down from
        // the crests and hollows at the sun's angle, as a cut-out would be.
        if (cut > 0.5 && orbit < 0.5 && inside > 0.0 && reformFront < 0.0 && push == 0.0) {
            float toward = sunAt > 0.5 ? 1.0 : -1.0;
            float base = curve * (1.0 - depth[l]);
            float out_ = a + toward * max(0.0, edge - r) / (curve * 1.6);
            for (int j = 0; j < 2; j++) {
                float h = base + maxAmp * amp[l] * heightOf(far_ ? farA : nearA, layerSeed, out_, sampleStep);
                out_ = a + toward * max(0.0, h - r) / (curve * 1.6);
            }
            // The slope over a few segments, so faces are broad and the fine grit doesn't
            // stripe them; a flat stays as it is
            float w = 4.0 * sampleStep;
            float rising = heightOf(far_ ? farA : nearA, layerSeed, out_ + w, sampleStep) - heightOf(far_ ? farA : nearA, layerSeed, out_ - w, sampleStep);
            tone = mix(tone, arrivalLight.rgb, toward * rising < -0.06 ? 0.14 : 0.0);
        }
        tone = mix(tone, arrivalLight.rgb, shine * mix(0.05, 0.95, crest));
        // The new day's rim lights the crests it crosses, and its line runs over the ground
        tone = mix(tone, dawnLight.rgb, max(dayLight * mix(0.05, 0.95, crest), dayLine));
        color = mix(color, vec4(tone, 1.0), inside);
    }

    // From space it's a real planet: continents, a day side and a night side, and a
    // thin glow of atmosphere catching the light around the edge
    vec3 sun = normalize(vec3(-0.55 + 1.1 * (sunAt - 0.25) / 0.5, -0.6, 0.58)); // 0.25 is today's light, upper left
    vec2 q = (p - center) / curve;
    float edgeDistance = length(q);
    vec4 rim = vec4(0.0);
    if (orbit > 0.001) {
        // Worked out for every pixel, so its slope across a pixel is known everywhere
        float depthZ = sqrt(max(0.0, 1.0 - edgeDistance * edgeDistance));
        vec3 normal = vec3(q, depthZ);
        float facing = dot(normal, sun);
        float aa = max(fwidth(facing), 1e-4);
        vec2 surface = vec2(atan(q.x, depthZ) + planetAngle, asin(clamp(q.y, -1.0, 1.0))) * 2.6;
        float ground = land(surface + 1.7 + seed - 1.2);
        float groundAa = max(fwidth(ground), 1e-4);
        if (edgeDistance < 1.0 + 2.0 / curve) {
            vec3 tone = mix(tone3.rgb, tone2.rgb, smoothstep(0.34, 0.42, ground));
            tone = mix(tone, tone1.rgb, smoothstep(0.44, 0.52, ground));
            tone = mix(tone, tone0.rgb, smoothstep(0.54, 0.62, ground));
            if (flatRim > 0.5) {
                // Continents cut out flat, each tone a clean shape, antialiased over a pixel
                tone = mix(tone3.rgb, tone2.rgb, clamp((ground - 0.38) / groundAa + 0.5, 0.0, 1.0));
                tone = mix(tone, tone1.rgb, clamp((ground - 0.48) / groundAa + 0.5, 0.0, 1.0));
                tone = mix(tone, tone0.rgb, clamp((ground - 0.58) / groundAa + 0.5, 0.0, 1.0));
            }
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
            // The edge of a sweep runs over the ground too, in that sky's light
            if (sweepReach > 0.0) {
                float line = clamp(0.75 + 0.5 - abs(sweepShape - sweepReach) / sweepSlope, 0.0, 1.0);
                lit = mix(lit, sweepLight.rgb, line);
            }
            color = mix(color, vec4(lit, 1.0), orbit * solid);
        }
        if (flatRim > 0.5) {
            // The limb: a flat ring of your low sky colour, three units wide
            float out_ = (edgeDistance - 1.0) * curve * k;
            float ring = clamp(out_ + 0.5, 0.0, 1.0) * clamp(3.0 * k - out_ + 0.5, 0.0, 1.0) * orbit;
            rim = vec4(rimTone.rgb * ring, ring);
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
