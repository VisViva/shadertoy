float EPSILON = 0.001;
float MIN_DISTANCE = 0.0;
float MAX_DISTANCE = 300.0;
int STEPS = 2000;

// Primitives

float plane(vec3 p)
{
	return p.y;
}
float sphere(vec3 p, float s)
{
    return length(p)-s;
}
float merge(float distA, float distB)
{
	return (distA<distB) ? distA : distB;
}

// Mapping

float map(in vec3 pos)
{
    return merge(
        plane(pos - vec3(0.0, 0.0, 0.0)),
        sphere(pos - vec3(0.0,0.25, 0.0), 0.25)
    );
}

// Tracing

vec3 ray(float fov, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

vec3 normal(vec3 p) {
    return normalize(vec3(
        map(vec3(p.x + EPSILON, p.y, p.z)) - map(vec3(p.x - EPSILON, p.y, p.z)),
        map(vec3(p.x, p.y + EPSILON, p.z)) - map(vec3(p.x, p.y - EPSILON, p.z)),
        map(vec3(p.x, p.y, p.z  + EPSILON)) - map(vec3(p.x, p.y, p.z - EPSILON))
    ));
}

float trace(vec3 o, vec3 r, float start, float end)
{
    float depth = start;
    for (int i = 0; i < STEPS; ++i) {
        float dist = map(o + r * depth);
        if (dist < EPSILON) {
			return depth;
        }
        depth += dist * 0.1;
        if (depth >= end) {
            return end;
        }
    }
    return depth;
}

// Rendering

vec3 phongContribForLight(vec3 k_d, vec3 k_s, float alpha, vec3 p, vec3 eye, vec3 lightPos, vec3 lightIntensity) {
    vec3 N = normal(p);
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
    vec3 light1Pos = vec3(1.0 * sin(iTime), 2.0, 2.0 * cos(iTime));
    vec3 light1Intensity = vec3(0.9, 0.9, 0.9);
    color += phongContribForLight(k_d, k_s, alpha, p, eye, light1Pos, light1Intensity);
    return color;
}

float shadow(in vec3 ro, in vec3 rd, in float mint, in float maxt)
{

    float res = 1.0;
    for( float t=mint; t < maxt; )
    {
        float h = map(ro + rd*t);
        if( h<0.0001 )
            return 0.0;
        res = min( res, 0.9*h/t );
        t += h*0.2;
    }
    return res;
}

// Entry

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    // Pixel ray
    
    vec3 r = ray(60.0, iResolution.xy, fragCoord);
    vec3 o = vec3(0.0, 0.3, 2.0);
    float t = trace(o, r, MIN_DISTANCE, MAX_DISTANCE);
    
    // Output
    
    vec3 color = vec3(1.0, 1.0, 1.0);
    float fog = 1.0 / (1.0 + t * t * 0.1);
    color *= shadow(o + t*r, vec3(1.0 * sin(iTime), 2.0, 2.0 * cos(iTime)), 0.01, 1.0);
    color *= fog;
    vec3 K_a = vec3(0.2, 0.2, 0.2);
    vec3 K_d = vec3(1.0, 1.0, 1.0);
    vec3 K_s = vec3(1.0, 1.0, 1.0);
    float shininess = 20.0;    
    color *= phongIllumination(K_a, K_d, K_s, shininess, o + t*r, o);
    fragColor = vec4(color,1.0);
}
