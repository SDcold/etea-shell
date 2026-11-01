#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 fire;
    float time;
    float heat;
    float ratio;
};

float hash(float x) {
    return fract(sin(x * 91.17) * 43758.5453);
}

// Coming down through the atmosphere: streaks of light rushing outward from below,
// and the air itself catching fire around the edges of the screen
void main() {
    vec2 p = vec2((qt_TexCoord0.x - 0.5) * ratio, qt_TexCoord0.y - 1.05);
    float angle = atan(p.x, -p.y);
    float reach = length(p);

    float lane = floor(angle * 70.0);
    float speed = 0.7 + hash(lane) * 1.4;
    float dash = fract(reach * (1.2 + hash(lane + 4.0)) - time * speed + hash(lane + 9.0));
    float streak = smoothstep(0.82, 1.0, dash) * smoothstep(0.1, 0.35, hash(lane + 2.0)) * smoothstep(0.1, 0.5, reach);

    float glow = pow(clamp(1.0 - reach * 0.75, 0.0, 1.0), 2.0) + pow(abs(qt_TexCoord0.x - 0.5) * 2.0, 4.0) * 0.5;

    vec3 color = fire.rgb * glow + mix(fire.rgb, vec3(1.0), 0.6) * streak;
    float alpha = clamp(glow * 0.9 + streak * 0.8, 0.0, 1.0) * heat;
    fragColor = vec4(color * heat, alpha) * qt_Opacity;
}
