// Outline, by GDQuest
// Source: https://github.com/GDQuest/godot-shaders
shader_type spatial;
render_mode cull_front, unshaded;



// Outline uniform variables.
uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width = 1.0;



// Wind uniform variables.
uniform vec2 wind = vec2(1.0, 0.0);
uniform float resistance = 1.0;
uniform float interval = 3.5;
uniform float height_offset = 0.0;
uniform vec2 seed;

uniform sampler2D wind_var_curve : hint_white;
uniform float var_intensity = 1.0;
uniform float var_frequency = 1.0;



// Helper functions from wind shader.
float rand(vec2 st) {
	return fract(sin(dot(st, vec2(12.9898,78.233))) * 43758.5453123);
}

float get_wind(float height, float time) {
	float max_strength = length(wind) * 0.005 / resistance;
	float min_strength = length(wind) * 0.001 / resistance;
	float diff = pow(max_strength - min_strength, 2.0);
	float strength = clamp(min_strength + diff + sin(time / interval) * diff, min_strength, max_strength) * 40.0;
	float var = texture(wind_var_curve, vec2(mod(time * var_frequency, 1.0), 0.0)).r * var_intensity;
	return (2.0 + sin(time) + var) * strength * max(0.0, height - height_offset);
}



void vertex() {
	vec3 worldcoords = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 wind_local_coords = (inverse(WORLD_MATRIX) * vec4(wind.x, 0.0, wind.y, 0.0)).xz;
	VERTEX.xz += wind_local_coords * get_wind(VERTEX.y, TIME * length(wind) + rand(fract(seed)) * 256.0);
	
	// Outline code.
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);
	clip_position.xy += normalize(clip_normal.xy) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;
	POSITION = clip_position;
}



void fragment() {
	ALBEDO = outline_color.rgb;
}


