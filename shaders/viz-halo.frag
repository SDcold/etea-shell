#version 440
#extension GL_GOOGLE_include_directive : enable
#include "visualizer.glsl"

// A frame of light hugging the screen edges, in the spirit of a voice assistant halo:
// the gradient drifts around the perimeter and the thickness breathes with the music
// rather than spiking on every beat. Light is added over the wallpaper like aurora,
// so alpha stays near zero.

float sdRoundBox(vec2 p, vec2 b, float r) {
    vec2 q = abs(p) - b + r;
    return min(max(q.x, q.y), 0.0) + length(max(q, 0.0)) - r;
}

// Palette roles differ wildly in brightness: a dark one would leave a dead
// sector on the frame. Bring every stop to the same luminance, hue untouched.
vec3 lift(vec3 c) {
    float lum = max(dot(c, vec3(0.299, 0.587, 0.114)), 0.001);
    return clamp(c * (0.72 / lum), 0.0, 1.0);
}

// Cyclic three stop gradient, so the sweep never shows a seam
vec3 wheel(float t) {
    float s = fract(t) * 3.0;
    float i = floor(s);
    float f = smoothstep(0.0, 1.0, s - i);
    vec3 a = i < 0.5 ? lift(color1.rgb) : (i < 1.5 ? lift(color2.rgb) : lift(color3.rgb));
    vec3 b = i < 0.5 ? lift(color2.rgb) : (i < 1.5 ? lift(color3.rgb) : lift(color1.rgb));
    return mix(a, b, f);
}

// Theme colors are pastel, push them away from grey so the light keeps a hue
vec3 vivid(vec3 c, float amount) {
    float grey = dot(c, vec3(0.299, 0.587, 0.114));
    return clamp(mix(vec3(grey), c, amount), 0.0, 1.0);
}

void main() {
    loadSpectrum();
    vec2 res = max(resolution, vec2(1.0));
    vec2 p = (qt_TexCoord0 - 0.5) * res;
    float mn = min(res.x, res.y);

    // Position around the frame, 0 on the right edge
    float t = fract(atan(p.y, p.x) / 6.28318530718 + 1.0);

    // Overall energy drives the breathing, the local band only ripples it.
    // Read the bands directly: the smoothing loop of band() is 5 spectrum
    // evaluations, and at full screen that is paid two million times a frame.
    float energy = (bandAt(1) + bandAt(4) + bandAt(9) + bandAt(18)) * 0.25;
    float ripple = spectrum(fract(t * 2.0));
    float swell = 0.18 + energy * 0.62 + ripple * 0.20 + bass * 0.30;

    float d = sdRoundBox(p, res * 0.5, mn * 0.06); // negative inside, zero on the edge
    float w = mn * (0.016 + 0.030 * swell);        // glow thickness in pixels

    // Everything deeper than the bloom is black: skip it rather than pay three
    // exponentials and two gradient lookups for nothing.
    if (d < -w * 14.0) {
        fragColor = vec4(0.0);
        return;
    }

    float core  = exp(d / (w * 0.25));
    float body  = exp(d / w);
    float bloom = exp(d / (w * 3.0));

    vec3 cBody  = vivid(wheel(t), 2.4);
    vec3 cBloom = vivid(wheel(t + 0.30), 2.0);

    // Cover rather than add. Adding light over the wallpaper disappears as soon as
    // the wallpaper is bright, so the frame carries its own opacity: opaque on the
    // edge, fading to nothing inwards.
    vec3 col = mix(cBloom, cBody, clamp(body + core, 0.0, 1.0));
    col *= 0.75 + 0.45 * swell;

    float alpha = clamp(core * 0.55 + body * 0.75 + bloom * 0.30, 0.0, 0.95) * fade;
    fragColor = vec4(col * alpha, alpha) * qt_Opacity;
}
