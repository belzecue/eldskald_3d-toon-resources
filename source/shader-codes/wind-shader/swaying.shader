// Swaying shader. Adaptaded to 3D from https://godotshaders.com/shader/2d-wind-sway/
// who adaptaded from HungryProton's version, which adapted from Maujoe. Original code:
// https://github.com/Maujoe/godot-simple-wind-shader-2d/tree/master/assets/maujoe.simple_wind_shader_2d
// I adapted it to 3D and added the variation curve for greater customization.
// 
// This is basically the base toon shader with added wind, which is done
// entirely on the vertex pass. If you want more properties like normal maps,
// depth maps or refraction, just replace the fragment and light passes of
// this shader with the ones that contains your desired properties. You also
// need to add their render modes as well.
shader_type spatial;



// Wind uniform variables.
uniform vec2 wind = vec2(1.0, 0.0);
uniform float resistance = 1.0;
uniform float interval = 3.5;
uniform float height_offset = 0.0;
uniform bool quadratic_deformation = false;
uniform vec2 seed;

uniform sampler2D wind_var_curve : hint_white;
uniform float var_intensity = 1.0;
uniform float var_frequency = 1.0;



// Base toon shader uniform variables. If you want to include more properties,
// just copy and paste their uniforms onto this list.
uniform vec4 albedo : hint_color = vec4(1.0);
uniform sampler2D texture_albedo : hint_albedo;

uniform float roughness : hint_range(0,1) = 1.0;
uniform float metallic : hint_range(0,1) = 0.0;
uniform sampler2D texture_surface : hint_white;

uniform float lighting : hint_range(0,1) = 0.0;
uniform float lighting_half_band : hint_range(0,1) = 0.25;
uniform float lighting_smoothness : hint_range(0,1) = 0.02;
uniform sampler2D lighting_curve : hint_white;

uniform float specular : hint_range(0,1) = 0.5;
uniform float specular_amount : hint_range(0,1) = 0.5;
uniform float specular_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_specular : hint_white;

uniform float rim : hint_range(0,1) = 0.5;
uniform float rim_amount : hint_range(0,1) = 0.2;
uniform float rim_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_rim : hint_white;

uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
uniform sampler2D texture_emission : hint_black_albedo;

uniform float ao_light_affect: hint_range(0,1) = 0.0;
uniform sampler2D ao_map : hint_white;

uniform float anisotropy_ratio: hint_range(-1,1) = 0.0;
uniform sampler2D anisotropy_flowmap : hint_aniso;

uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);



// Known RNG method from the Book of Shaders (https://thebookofshaders.com/10/)
float rand(vec2 st) {
	return fract(sin(dot(st, vec2(12.9898,78.233))) * 43758.5453123);
}

// Wind function from godotshaders, slightly modified.
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
	
	UV = UV * uv_scale.xy + uv_offset.xy; // This line must be kept.
}



// Base toon shader. Replace those functions to add more properties.
void fragment() {
	ALBEDO = albedo.rgb * texture(texture_albedo, UV).rgb;
	ROUGHNESS = roughness * texture(texture_surface, UV).r;
	METALLIC = metallic * texture(texture_surface, UV).g;
	EMISSION = (emission.rgb + texture(texture_emission, UV).rgb) * emission_energy;
	AO = texture(ao_map, UV).r;
	AO_LIGHT_AFFECT = ao_light_affect;
}

const float PI = 3.14159265358979323846;

void light() {
	float spec_value = specular * texture(texture_specular, UV).r;
	float spec_gloss = pow(2.0, 8.0 * (1.0 - specular_amount * texture(texture_specular, UV).g));
	float spec_smooth = specular_smoothness * texture(texture_specular, UV).b;
	float rim_value = rim * texture(texture_rim, UV).r;
	float rim_width = rim_amount * texture(texture_rim, UV).g;
	float rim_smooth = rim_smoothness * texture(texture_rim, UV).b;
	
	vec3 litness = texture(lighting_curve, vec2(dot(LIGHT, NORMAL), 0.0)).r * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * litness;
	
	vec3 aniso_dir = (texture(anisotropy_flowmap, UV).rgb * 2.0 - 1.0);
	vec3 half = normalize(VIEW + LIGHT);
	float aniso = max(0, sin(dot(normalize(NORMAL + aniso_dir), half) * PI));
	float spec = mix(dot(NORMAL, half), aniso, anisotropy_ratio * texture(anisotropy_flowmap, UV).a);
	float spec_intensity = pow(spec, spec_gloss * spec_gloss);
	spec_intensity = smoothstep(0.05, 0.05 + spec_smooth, spec_intensity);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, spec_value) * spec_intensity * litness;
	
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_width), dot(LIGHT, NORMAL));
	float rim_intensity = smoothstep(rim_threshold - rim_smooth/2.0, rim_threshold + rim_smooth/2.0, rim_dot);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, rim_value) * rim_intensity * litness;
}


