// Grass shader. This is the wind code with only the application of albedo.
// We're not gonna process specular, and the diffuse is independant of light
// and normal vectors, it is only affected by attenuation. 
shader_type spatial;

uniform vec2 wind = vec2(1.0, 0.0);
uniform float resistance = 1.0;
uniform float interval = 3.5;
uniform float height_offset = 0.0;
uniform bool quadratic_deformation = false;
uniform vec2 seed;

uniform sampler2D wind_var_curve : hint_white;
uniform float var_intensity = 1.0;
uniform float var_frequency = 1.0;

uniform vec4 albedo : hint_color = vec4(1.0); // The only non-wind related uniform we need.



// Wind functions.
float rand(vec2 st) {
	return fract(sin(dot(st, vec2(12.9898,78.233))) * 43758.5453123);
}

float get_wind(float height, float time) {
	float max_strength = length(wind) * 0.005 / resistance;
	float min_strength = length(wind) * 0.001 / resistance;
	float diff = pow(max_strength - min_strength, 2.0);
	float strength = clamp(min_strength + diff + sin(time / interval) * diff, min_strength, max_strength) * 40.0;
	float var = (2.0 * texture(wind_var_curve, vec2(mod(time * var_frequency, 1.0), 0.0)).r - 1.0 ) * var_intensity;
	float deform = (1.0 + sin(time) + var) * strength;
	float height_scale = max(0.0, height - height_offset);
	float deform_type = quadratic_deformation ? height_scale * height_scale : height_scale;
	return deform * deform_type;
}

void vertex() {
	vec3 worldcoords = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 wind_local_coords = (inverse(WORLD_MATRIX) * vec4(wind.x, 0.0, wind.y, 0.0)).xz;
	VERTEX.xz += wind_local_coords * get_wind(VERTEX.y, TIME * length(wind) + rand(fract(seed)) * 256.0);
}



// This is all we need for a cheap, good looking grass.
void fragment() {
	ALBEDO = albedo.rgb;
}

void light() {
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * ATTENUATION;
}


