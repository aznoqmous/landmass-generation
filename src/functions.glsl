#define PI 3.141592653589793238462

uniform vec3 uColor;
uniform vec3 uTopColor;
uniform vec3 uFogColor;
uniform vec3 uCameraPosition;
uniform float uFogMaxDistance;
uniform float uTime;
uniform float uSeed;
uniform bool uBlinn;
uniform float uShininess;
uniform sampler2D texture1;

vec3 _LightDirection = vec3(1.0, 1.0, -1.0);
vec2 _AngularVariance = vec2(1.0, 1.0);
float _TerrainHeight = 0.5;
float _GradientRotation = 12.0;
float _Lacunarity = 1.0;
float _InitialAmplitude = 1.0;
float _NoiseRotation = 1.0;
float _AmplitudeDecay = 0.5;
float _Octaves = 12.0;
float _FrequencyVarianceLowerBound = 1.0;
float _FrequencyVarianceUpperBound = 1.0;

// float clamp(float a, float vmin, float vmax){
//     return max(min(a, vmax), vmin);
// }

// UE4's PseudoRandom function
// https://github.com/EpicGames/UnrealEngine/blob/release/Engine/Shaders/Private/Random.ush
float pseudo(vec2 v) {
    v = fract(v/128.)*128. + vec2(-64.340622, -72.465622);
    return fract(dot(v.xyx * v.xyy, vec3(20.390625, 60.703125, 2.4281209)));
}

// Takes our xz positions and turns them into a random number between 0 and 1 using the above pseudo random function
float HashPosition(vec2 pos) {
    return pseudo(pos * vec2(uSeed, uSeed + 4.0));
}

// Generates a random gradient vector for the perlin noise lattice points, watch my perlin noise video for a more in depth explanation
vec2 RandVector(float seed) {
    float theta = seed * 360.0 * 2.0 - 360.0;
    theta += _GradientRotation;
    theta = theta * PI / 180.0;
    return normalize(vec2(cos(theta), sin(theta)));
}

// Normal smoothstep is cubic -- to avoid discontinuities in the gradient, we use a quintic interpolation instead as explained in my perlin noise video
vec2 quinticInterpolation(vec2 t) {
    return t * t * t * (t * (t * vec2(6) - vec2(15)) + vec2(10));
}

// Derivative of above function
vec2 quinticDerivative(vec2 t) {
    return vec2(30) * t * t * (t * (t - vec2(2)) + vec2(1));
}

// it's perlin noise that returns the noise in the x component and the derivatives in the yz components as explained in my perlin noise video
vec3 perlin_noise2D(vec2 pos) {
    vec2 latticeMin = floor(pos);
    vec2 latticeMax = ceil(pos);

    vec2 remainder = fract(pos);

    // Lattice Corners
    vec2 c00 = latticeMin;
    vec2 c10 = vec2(latticeMax.x, latticeMin.y);
    vec2 c01 = vec2(latticeMin.x, latticeMax.y);
    vec2 c11 = latticeMax;

    // Gradient Vectors assigned to each corner
    vec2 g00 = RandVector(HashPosition(c00));
    vec2 g10 = RandVector(HashPosition(c10));
    vec2 g01 = RandVector(HashPosition(c01));
    vec2 g11 = RandVector(HashPosition(c11));

    // Directions to position from lattice corners
    vec2 p0 = remainder;
    vec2 p1 = p0 - vec2(1.0);

    vec2 p00 = p0;
    vec2 p10 = vec2(p1.x, p0.y);
    vec2 p01 = vec2(p0.x, p1.y);
    vec2 p11 = p1;
    
    vec2 u = quinticInterpolation(remainder);
    vec2 du = quinticDerivative(remainder);

    float a = dot(g00, p00);
    float b = dot(g10, p10);
    float c = dot(g01, p01);
    float d = dot(g11, p11);

    // Expanded interpolation freaks of nature from https://iquilezles.org/articles/gradientnoise/
    float noise = a + u.x * (b - a) + u.y * (c - a) + u.x * u.y * (a - b - c + d);

    vec2 gradient = g00 + u.x * (g10 - g00) + u.y * (g01 - g00) + u.x * u.y * (g00 - g10 - g01 + g11) + du * (u.yx * (a - b - c + d) + vec2(b, c) - a);
    return vec3(noise, gradient);
}

// The fractional brownian motion that sums many noise values as explained in the video accompanying this project
vec3 fbm(vec2 pos) {
    float lacunarity = _Lacunarity;
    float amplitude = _InitialAmplitude;

    // height sum
    float height = 0.0;

    // derivative sum
    vec2 grad = vec2(0.0);

    // accumulated rotations
    mat2 m = mat2(1.0, 0.0,
                    0.0, 1.0);

    // generate random angle variance if applicable
    float angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(uSeed, 827)));
    float theta = (_NoiseRotation + angle_variance) * PI / 180.0;

    // rotation matrix
    mat2 m2 = mat2(cos(theta), -sin(theta),
                    sin(theta),  cos(theta));
        
    mat2 m2i = inverse(m2);

    for(int i = 0; i < int(_Octaves); ++i) {
        vec3 n = perlin_noise2D(pos);
        
        // add height scaled by current amplitude
        height += amplitude * n.x;
        
        // add gradient scaled by amplitude and transformed by accumulated rotations
        grad += amplitude * m * n.yz;
        
        // apply amplitude decay to reduce impact of next noise layer
        amplitude *= _AmplitudeDecay;
        
        // generate random angle variance if applicable
        angle_variance = mix(_AngularVariance.x, _AngularVariance.y, HashPosition(vec2(i * 419, uSeed)));
        theta = (_NoiseRotation + angle_variance) * PI / 180.0;

        // reconstruct rotation matrix, kind of a performance stink since this is technically expensive and doesn't need to be done if no random angle variance but whatever it's 2025
        m2 = mat2(cos(theta), -sin(theta),
                    sin(theta),  cos(theta));
        
        m2i = inverse(m2);

        // generate frequency variance if applicable
        float freq_variance = mix(_FrequencyVarianceLowerBound, _FrequencyVarianceUpperBound, HashPosition(vec2(i * 422, uSeed)));

        // apply frequency adjustment to sample position for next noise layer
        pos = (lacunarity + freq_variance) * m2 * pos;
        m = (lacunarity + freq_variance) * m2i * m;
    }

    return vec3(height, grad);
}