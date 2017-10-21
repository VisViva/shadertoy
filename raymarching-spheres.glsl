float map(vec3 p)
{
    vec3 q = fract(p) * 2.  - 1.;
    return length(q) - 0.1;
}

float trace(vec3 o, vec3 r, float start, float end)
{
    float depth = 0.0;
    for (int i = 0; i < 20; ++i) {
        float dist = map(o + r * depth);
        if (dist < 0.0001) {
			return depth;
        }
        depth += dist * 0.4;
        if (depth >= end) {
            return end;
        }
    }
    return depth;
}

vec3 ray(float fov, vec2 size, vec2 fragCoord) {
    vec2 xy = fragCoord - size / 2.0;
    float z = size.y / tan(radians(fov) / 2.0);
    return normalize(vec3(xy, -z));
}

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	  vec2 uv = fragCoord.xy / iResolution.xy;
    uv = uv * 2. - 1.;
    uv.x *= iResolution.x / iResolution.y;    
    vec3 r = ray(60.0, iResolution.xy, fragCoord);    
    float the = iTime;
    r.xy *= mat2(cos(the), -sin(the), sin(the), cos(the));    
    vec3 o = vec3(0.0, iTime, 6.0);    
    float t = trace(o, r, 0.0, 1500.0);    
    if (t > 100.0 - 0.0001) {
        fragColor = vec4(0.0, 0.0, 0.0, 0.0);
	      return;
    }    
    float fog = 1.0 / (1.0 + t * t * 0.1);
    vec3 fc = vec3(fog);  
	  fragColor = vec4(fc,1.0);
}
