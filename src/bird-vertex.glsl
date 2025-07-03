#include functions.glsl

varying vec2 vUv;
varying vec3 vPosition;
void main()
{
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    float wingsHeight = cos(uv.x * 2.0 * PI) * 0.002 * sin(modelPosition.y * 123456.0 + uTime * 5.0);
    vec4 endPosition =  vec4(modelPosition.x, modelPosition.y + wingsHeight, modelPosition.z, 1.0);
    vec4 viewPosition = viewMatrix * endPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    gl_Position = projectedPosition;
    vUv = uv;
    vPosition = modelPosition.xyz;
}