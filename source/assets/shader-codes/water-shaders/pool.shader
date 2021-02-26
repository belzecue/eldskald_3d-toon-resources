// A modified sea shader to fix the normal vector in order
// to produce reflections. Has no textures and less freedom
// over waves.
shader_type spatial;
render_mode depth_draw_always;



uniform vec4 water_color : hint_color = vec4(1.0);
uniform float reflectiveness: hint_range(0,1) = 0.8;
uniform float agitation: hint_range(0,1) = 0.0;
uniform float brightness = 1.0;
uniform float edge_brightness = 1.0;
uniform bool fixed_edge_lighting = false;

uniform float edge_smoothness = 0.05;
uniform float edge_max_threshold = 0.5;
uniform float edge_displacement = 0.6;
uniform float near = 0.15;
uniform float far = 300.0;

uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);

uniform sampler2D edge_noise : hint_white;
uniform sampler2D agitation_noise_1 : hint_normal;
uniform sampler2D agitation_noise_2 : hint_normal;



void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}



// This function turns distances from depth texture into linear system.
float linearize(float c_depth) {
	c_depth = 2.0 * c_depth - 1.0;
	return near * far / (far + c_depth * (near - far));
}



void fragment() {
	// These are here just for the looks of reflections. Low roughness on agitated
	// waters look less toony, but on still waters it looks good.
	METALLIC = reflectiveness;
	ROUGHNESS = clamp(1.0 - reflectiveness + 5.0 * agitation, 0.0, 1.0);
	
	// Edge ripples code directly from sea shader, but this time instead of painting
	// with water and edge colors, we paint it with black and white to help the light
	// pass detect edges instead, since we can't access the depth texture there.
	float zdepth = linearize(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float zpos = linearize(FRAGCOORD.z);
	float diff = zdepth - zpos;
	vec2 edge_displ = texture(edge_noise, UV - TIME * (0.2 + agitation * 3.0) / 16.0).rg;
	edge_displ = ((edge_displ * 2.0) - 1.0) * edge_displacement;
	diff += edge_displ.x;
	float edge_smooth = smoothstep(edge_max_threshold, edge_max_threshold + edge_smoothness, diff);
	vec4 col = mix(vec4(1.0), vec4(0.0), edge_smooth);
	ALBEDO = col.rgb;
	
	// We'll make the ripples by changing the normal map, since these waves are more detailed
	// and don't need to visibly go up and down other meshes.
	vec3 agi_1 = texture(agitation_noise_1, UV + vec2(TIME * 0.25 * agitation, 0.0)).rgb;
	vec3 agi_2 = texture(agitation_noise_2, UV + vec2(0.0, TIME * 0.25 * agitation)).rgb;
	NORMALMAP = mix(agi_1, agi_2, 0.5);
	NORMALMAP_DEPTH = agitation*4.0;
	
	// Refraction from Godot's base code, a little bit modified to look better.
	vec3 normal = 2.0 * NORMALMAP - vec3(1.0);
	vec2 ref_ofs = SCREEN_UV - normal.xy * agitation * 0.12;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, 0.0).rgb * (1.0 - water_color.a);
}







const float lighting = 0.0;
const float lighting_smoothness = 0.02;

const float specular_glossiness = 16.0;
const float specular_smoothness = 0.02;

const float rim_amount = 0.2;
const float rim_smoothness = 0.02;

void light() {
	// Lighting, specular and rim directly from base toon shader. The agitation
	// value controls rim and specular values. We use water color instead of albedo
	// to keep albedo solely for edge detection.
	
	// Litness has no half band, and we add 0.5 to it to make better shaded parts.
	float shade = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 litness = (smoothstep(0.0, lighting_smoothness, shade)/2.0 + 0.5) * ATTENUATION;
	DIFFUSE_LIGHT.r += water_color.r * water_color.a * LIGHT_COLOR.r * mix(lighting, 1.0, litness.r);
	DIFFUSE_LIGHT.g += water_color.g * water_color.a * LIGHT_COLOR.g * mix(lighting, 1.0, litness.g);
	DIFFUSE_LIGHT.b += water_color.b * water_color.a * LIGHT_COLOR.b * mix(lighting, 1.0, litness.b);
	
	// Normal specular, with agitation and reflectiveness controling its amount.
	vec3 half = normalize(VIEW + LIGHT);
	float spec_intensity = pow(dot(NORMAL, half), specular_glossiness * specular_glossiness);
	spec_intensity = smoothstep(0.05, 0.05 + specular_smoothness, spec_intensity);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, agitation * reflectiveness) * spec_intensity * litness * brightness;
	
	// Rim lighting with agitation and reflectiveness controling its amount.
	// We also blend it with specular by multiplying the final value by
	// 1 - spec_intensity, try removing it to see how it looks.
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_amount), shade);
	float rim_intensity = smoothstep(rim_threshold - rim_smoothness/2.0, rim_threshold + rim_smoothness/2.0, rim_dot);
	float rim_value = agitation * reflectiveness;
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, rim_value) * rim_intensity * litness * (1.0 - spec_intensity) * brightness;
	
	// We detect edge here by reading the albedo. If it's black
	// it's not edge, if it's white it's edge, and every shade of
	// gray in between is smoothing.
	float edge_factor = edge_brightness * (1.0 - rim_intensity) * (1.0 - spec_intensity);
	float edge_value = fixed_edge_lighting ? 0.5 : agitation * reflectiveness;
	SPECULAR_LIGHT += ALBEDO.r * mix(vec3(0.0), LIGHT_COLOR, edge_value) * edge_factor * litness;
}


