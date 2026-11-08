#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 light; // the ink, in the light of the sky being worn
    vec2 resolution;
    vec2 center; // the planet's centre, in pixels
    float radius; // the belt's, in pixels
    float seed;
    // Where the moons hang, worked out as SkyMoon does: the belt has turned this far past
    // the zenith's moon, and there are this many items before and after it
    float turned;
    float before;
    float after;
    float moonHalf; // a moon's half height on the belt, and the porthole's, in pixels
    float portholeHalf;
    float screenAspect;
    float room; // how far the line stays clear of each moon
};

// HandCard's wobble, so the belt is drawn by the same hand as every card
float wobble(float along) {
    return sin(along * 0.021 + seed) * 0.7 + sin(along * 0.047 + seed * 2.3) * 0.4 + sin(along * 0.11 + seed * 5.1) * 0.2;
}

// The edge of the air: HandCard's doubled ink line, as a great arc round the planet
void main() {
    vec2 p = qt_TexCoord0 * resolution;
    vec2 d = p - center;
    float r = length(d);
    if (abs(r - radius) > 6.0) {
        fragColor = vec4(0.0);
        return;
    }
    float angle = atan(d.x, -d.y);
    float along = angle * radius;
    float drift = wobble(along);
    float line = clamp(0.65 + 0.5 - abs(r - (radius + drift)), 0.0, 1.0) * 0.72;
    float echo = clamp(0.4 + 0.5 - abs(r - (radius - 1.6 + drift)), 0.0, 1.0) * 0.72 * 0.38;

    // Lifted around each moon, cut cleanly over one pixel along the arc. The zenith is a
    // loupe: a moon d places along hangs at 11d + 3.5·tanh(11d/7) degrees.
    float open = 1.0;
    for (int k = -7; k <= 7; k++) {
        if (float(k) < -before || float(k) > after)
            continue;
        float d = float(k) - turned;
        float at = radians(11.0 * d + 3.5 * tanh(11.0 * d / 7.0));
        float t = min(1.0, abs(d));
        float z = 1.0 - t * t * (3.0 - 2.0 * t);
        float half_ = mix(moonHalf, portholeHalf, z);
        float reach = max(half_ * (1.0 + (screenAspect - 1.0) * z), half_) + room;
        open = min(open, clamp((abs(angle - at) - reach / radius) * radius + 0.5, 0.0, 1.0));
    }
    float ink = max(line, echo) * open;
    fragColor = vec4(light.rgb, 1.0) * ink * qt_Opacity;
}
