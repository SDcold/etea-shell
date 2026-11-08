#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 light; // your world's light, for the star marking your sky
    vec2 resolution;
    vec2 center; // the planet's centre, in pixels
    float radius; // the planet's, in pixels
    float count; // how many items, one tick each
    float spread; // half the arc they take, in radians
    float grow; // the ticks' length, 0 to 1
    float unit;
    float at; // where the zenith is along the folder, in items, fractional while turning
    float yours; // which item is your sky
};

layout(binding = 1) uniform sampler2D strip; // each item's colour, one pixel each

// ETEA's star as a distance: |x|^0.62 + |y|^0.62 = r^0.62
float starShape(vec2 p) {
    vec2 a = abs(p);
    return pow(pow(a.x, 0.62) + pow(a.y, 0.62), 1.0 / 0.62);
}

// The whole folder as a band of colour along your horizon: one tick per picture, just
// outside the planet's limb, each in its own colour. A lit star rides at the zenith's
// place, a small one marks the sky you wear.
void main() {
    vec2 p = qt_TexCoord0 * resolution;
    vec2 d = p - center;
    float r = length(d);
    float angle = atan(d.x, -d.y);
    float inner = radius + 3.0 * unit;
    float step_ = 2.0 * spread / max(1.0, count - 1.0);

    // The stars, a little further out, worked out first so their edges can be measured
    float out_ = inner + 14.0 * unit;
    float yoursAngle = -spread + yours * step_;
    float small = starShape(p - center - out_ * vec2(sin(yoursAngle), -cos(yoursAngle)));
    float atAngle = -spread + clamp(at, 0.0, count - 1.0) * step_;
    float big = starShape(p - center - out_ * vec2(sin(atAngle), -cos(atAngle)));
    float smallSlope = max(length(vec2(dFdx(small), dFdy(small))), 1e-4);
    float bigSlope = max(length(vec2(dFdx(big), dFdy(big))), 1e-4);

    if (r < inner - 2.0 || r > inner + 24.0 * unit || abs(angle) > spread + 0.1) {
        fragColor = vec4(0.0);
        return;
    }
    vec4 color = vec4(0.0);

    // The nearest tick, and how far along the arc we are from it
    float index = clamp(floor((angle + spread) / step_ + 0.5), 0.0, count - 1.0);
    float across = (angle - (-spread + index * step_)) * r;
    float len = 6.0 * unit * grow * (abs(index - yours) < 0.5 ? 1.6 : 1.0);
    float tick = clamp(1.1 - abs(across) + 0.5, 0.0, 1.0) * clamp(r - inner + 0.5, 0.0, 1.0) * clamp(inner + len - r + 0.5, 0.0, 1.0);
    vec3 tone = textureLod(strip, vec2((index + 0.5) / count, 0.5), 0.0).rgb;
    color = vec4(tone, 1.0) * tick * step(0.01, grow);

    float mark = clamp((3.2 * unit * grow - small) / smallSlope + 0.5, 0.0, 1.0);
    color = vec4(light.rgb, 1.0) * mark + color * (1.0 - mark);
    float lit = clamp((6.0 * unit * grow - big) / bigSlope + 0.5, 0.0, 1.0);
    color = vec4(1.0) * lit + color * (1.0 - lit);
    fragColor = color * qt_Opacity;
}
