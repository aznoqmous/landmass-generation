#include functions.glsl;

varying vec3 vPosition;
void main()
{
    vec4 modelPosition = modelMatrix * vec4(position, 1.0);
    vec4 endPosition =  vec4(modelPosition.x, _TerrainHeight * fbm(modelPosition.xz).x, modelPosition.z, 1.0);
    vec4 viewPosition = viewMatrix * endPosition;
    vec4 projectedPosition = projectionMatrix * viewPosition;
    gl_Position = projectedPosition;
    vPosition = modelPosition.xyz;
}