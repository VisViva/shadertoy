float EPSILON = 0.005;
float MIN_DISTANCE = 2.0;
float MAX_DISTANCE = 200.0;
float THETA = 0.005;

float cubeSDF(vec3 p) {
    vec3 d = abs(p) - vec3(0.35, 1.6, 0.4);
    float insideDistance = min(max(d.x, max(d.y, d.z)), 0.0);
    float outsideDistance = length(max(d, 0.0));    
    return insideDistance + outsideDistance;
}

float differenceSDF(float distA, float distB) {
    return max(distA, -distB);
}

float unionSDF(float distA, float distB) {
    return max(distA, distB);
}

float map(vec3 p)
{
    vec3 q = fract(p) * 2.  - 1.;
    return unionSDF(differenceSDF(cubeSDF(q), length(q) - 0.5),  length(q) - 0.7);
}

float trace(vec3 o, vec3 r, float start, float end)
{
    float depth = start;
    for (int i = 0; i < 300; ++i) {
        float dist = map(o + r * depth);
        depth += dist * 0.2;
    }
    return depth;
}

vec3 ray(float fov, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 estimateNormal(vec3 p) {
    return normalize(vec3(
        map(vec3(p.x + THETA, p.y, p.z)) - map(vec3(p.x - THETA, p.y, p.z)),
        map(vec3(p.x, p.y + THETA, p.z)) - map(vec3(p.x, p.y - THETA, p.z)),
        map(vec3(p.x, p.y, p.z  + THETA)) - map(vec3(p.x, p.y, p.z - THETA))
    ));
}

vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntensity) {
    vec3 N = estimateNormal(p);
    vec3 L = normalize(lightPos - p);
    vec3 V = normalize(eye - p);
    vec3 R = normalize(reflect(-L, N));    
    float dotLN = dot(L, N);
    float dotRV = dot(R, V);    
    if (dotLN < 0.0) {
        return vec3(0.0, 0.0, 0.0);
    }     
    if (dotRV < 0.0) {
        return lightIntensity * (k_d * dotLN);
    }
    return lightIntensity * (k_d * dotLN + k_s * pow(dotRV, alpha));
}

vec3 phongIllumination(vec3 k_a, vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye) {
    const vec3 ambientLight = 0.5 * vec3(1.0, 1.0, 1.0);
    vec3 color = ambientLight * k_a;
    vec3 light1Pos = vec3(4.0, 2.0, 4.0);
    vec3 light1Intensity = vec3(0.7, 0.7, 0.7);
    color += phongContribForLight(k_d, k_s, alpha, p, eye, light1Pos, light1Intensity);
    vec3 light2Pos = vec3(2.0 * sin(0.37 * iTime), 2.0 * cos(0.37 * iTime), 2.0);
    vec3 light2Intensity = vec3(0.4, 0.4, 0.4);    
    color += phongContribForLight(k_d, k_s, alpha, p, eye, light2Pos, light2Intensity);    
    return color;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;    
    vec3 r = ray(60.0, iResolution.xy, fragCoord);    
    float the = iTime/4.;
    r.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));    
    vec3 o = vec3(0.0, iTime / 2., 6.0);    
    float t = trace(o, r, MIN_DISTANCE, MAX_DISTANCE);    
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = vec3(fog);  
    vec3 K_a = vec3(0.4, 0.4, 0.4);
    vec3 K_d = vec3(0.8, 0.8, 0.8);
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 10.0;    
    vec3 color = phongIllumination(K_a, K_d, K_s, shininess, o + t*r, o);    
    fragColor = vec4(fc*color,1.0);
}
