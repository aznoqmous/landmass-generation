#include functions.glsl;
varying vec3 vPosition;


void main()
{
    // _LightDirection = vec3(cos(uTime), sin(uTime), -1.0);

    vec3 n = _TerrainHeight * fbm(vPosition.xz);
    vec3 normal = normalize(vec3(-n.y, 1, -n.z));

    vec3 color = mix(uColor, uTopColor, n.x / _TerrainHeight);
    vec3 textureColor = texture2D(texture1, mod(vPosition.xz * 10.0, vec2(1.0))).xyz;
    color *= pow(textureColor, vec3(1.0));

    vec3 ambientLight = 0.3 * color;
    vec3 diffuseLight = 0.5 * clamp(dot(normalize(_LightDirection), normal), 0.0, 1.0)  * color;

    vec3 specularLight = vec3(0.0);
    vec3 vertexToEye = normalize(uCameraPosition - vPosition);
    if(uBlinn){
        vec3 halfway = normalize(_LightDirection + vertexToEye);
        float shininess = uShininess * 2.0;
        float specularFactor = pow(max(dot(normal, halfway), 0.0), shininess);
        specularLight = specularFactor * color;
    }
    else {
        vec3 lightReflect = normalize(reflect(-_LightDirection, normal));
        float shininess = uShininess;
        float specularFactor = pow(max(dot(vertexToEye, lightReflect), 0.0), shininess);
        specularLight = specularFactor * color;
    }

    vec3 lit = clamp(diffuseLight + ambientLight + specularLight, vec3(0.0), vec3(1.0));
    
    float fogDistance = clamp(1.0 - distance(uCameraPosition, vPosition) / uFogMaxDistance, 0.0, 1.0);

    // clouds
    lit *= clamp(fbm(vPosition.xz / 2.0 + vec2(uTime / 45.0, uTime / 55.0) + vec2(132.0, 2154.0)).x * 10.0, 0.6, 1.0);
    
    lit = pow(lit, vec3(2.2)) * 2.0 + lit;
    lit = mix(uFogColor, lit, fogDistance);

    gl_FragColor = vec4(lit, 1.0);
}