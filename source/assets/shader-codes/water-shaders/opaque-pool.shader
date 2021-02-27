// Opaque water pool for when you want screen-space reflections.
// Has no refraction and no edge ripples. You can use ripple nodes
// on top of those, they still look good.
shader_type spatial;
render_mode depth_draw_always;



uniform vec4 water_color : hint_color = vec4(1.0);
uniform float reflectiveness: hint_range(0,1) = 1.0;
uniform float agitation: hint_range(0,1) = 0.0;
uniform float brightness = 1.0;

uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);

uniform sampler2D edge_noise : hint_white;
uniform sampler2D agitation_noise_1 : hint_normal;
uniform sampler2D agitation_noise_2 : hint_normal;



void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}



void fragment() {
	// These are here just for the looks of reflections. Low roughness on agitated
	// waters look less toony, but on still waters it looks good.
	METALLIC = reflectiveness;
	ROUGHNESS = clamp(1.0 - reflectiveness + 5.0 * agitation, 0.0, 1.0);
	ALBEDO = water_color.rgb;
	
	// We'll make the ripples by changing the normal map, since these waves are more detailed
	// and don't need to visibly go up and down other meshes.
	vec3 agi_1 = texture(agitation_noise_1, UV + vec2(TIME * 0.25 * agitation, 0.0)).rgb;
	vec3 agi_2 = texture(agitation_noise_2, UV + vec2(0.0, TIME * 0.25 * agitation)).rgb;
	NORMALMAP = mix(agi_1, agi_2, 0.5);
	NORMALMAP_DEPTH = agitation*4.0;
}



// Lighting uniforms from base toon code turned into constants.
// The ones missing are actually calculated by reflectiveness
// and agitation uniforms.
const float lighting = 0.0;
const float lighting_smoothness = 0.02;

const float specular_glossiness = 16.0;
const float specular_smoothness = 0.02;

const float rim_amount = 0.2;
const float rim_smoothness = 0.02;

void light() {
	// Litness has no half band, and we add 0.5 to it to make better shaded parts.
	float shade = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 litness = (smoothstep(0.0, lighting_smoothness, shade)/2.0 + 0.5) * ATTENUATION;
	DIFFUSE_LIGHT.r += ALBEDO.r * LIGHT_COLOR.r * mix(lighting, 1.0, litness.r);
	DIFFUSE_LIGHT.g += ALBEDO.g * LIGHT_COLOR.g * mix(lighting, 1.0, litness.g);
	DIFFUSE_LIGHT.b += ALBEDO.b * LIGHT_COLOR.b * mix(lighting, 1.0, litness.b);
	
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
}


