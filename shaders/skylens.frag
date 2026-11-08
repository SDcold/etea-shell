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
    float grain;
};

layout(binding = 1) uniform sampler2D picture; // the background's own texture
layout(binding = 2) uniform sampler2D small; // the same picture, 512 wide and mipmapped

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
    float inside = clamp(reach / aspect - r + 0.5, 0.0, 1.0);
    if (inside <= 0.0) {
        fragColor = vec4(0.0);
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

    float n = mix(0.376, 0.627, hash(floor(gl_FragCoord.xy)));
    color = mix(color, overlay(color, n), grain) + (n - 0.5) * grain * 0.065 + painted * 0.011;
    fragColor = vec4(color, 1.0) * inside * qt_Opacity;
}
