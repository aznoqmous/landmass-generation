#include functions.glsl

varying vec2 vUv;
varying vec3 vPosition;
void main()
{
    vec4 color = texture2D(texture1, vUv);
    color *= clamp(fbm(vPosition.xz / 2.0 + vec2(uTime / 5.0, 1.0)).x + vec4(0.5), 0.6, 1.5);
    gl_FragColor = color;
}