// This is basically the pool shader without the edge ripples and
// with a single normal map moving in a single direction.
shader_type spatial;
render_mode depth_draw_always;



uniform vec4 water_color : hint_color = vec4(1.0);
uniform float reflectiveness: hint_range(0,1) = 0.8;
uniform float agitation: hint_range(0,1) = 0.2;
uniform float refraction: hint_range(0,1) = 0.16;
uniform float brightness = 1.0;
uniform float flow_speed = 1.0;
uniform sampler2D normal_map: hint_normal;

uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);



void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}



// Pool shader without the edge ripples implementation.
void fragment() {
	METALLIC = reflectiveness;
	ROUGHNESS = clamp(1.0 - reflectiveness + 5.0 * agitation, 0.0, 1.0);
	
	// We just need one normal map here, and it always moves up on the y direction.
	// Make your river/falls models with that in mind.
	NORMALMAP = texture(normal_map, UV + vec2(0.0, flow_speed*TIME)).rgb;
	NORMALMAP_DEPTH = agitation*4.0;
	
	vec3 normal = 2.0 * NORMALMAP - vec3(1.0);
	vec2 ref_ofs = SCREEN_UV - normal.xy * agitation * refraction / length(VERTEX);
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, 0.0).rgb * (1.0 - water_color.a);
	ALBEDO = water_color.rgb * water_color.a;
}



const float lighting = 0.0;
const float lighting_smoothness = 0.02;

const float specular_glossiness = 16.0;
const float specular_smoothness = 0.02;

const float rim_amount = 0.2;
const float rim_smoothness = 0.02;

// Pool light pass without the albedo to edge ripples trick.
void light() {
	float shade = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	vec3 litness = (smoothstep(0.0, lighting_smoothness, shade)/2.0 + 0.5) * ATTENUATION;
	DIFFUSE_LIGHT.r += ALBEDO.r * LIGHT_COLOR.r * mix(lighting, 1.0, litness.r);
	DIFFUSE_LIGHT.g += ALBEDO.g * LIGHT_COLOR.g * mix(lighting, 1.0, litness.g);
	DIFFUSE_LIGHT.b += ALBEDO.b * LIGHT_COLOR.b * mix(lighting, 1.0, litness.b);
	
	vec3 half = normalize(VIEW + LIGHT);
	float spec_intensity = pow(dot(NORMAL, half), specular_glossiness * specular_glossiness);
	spec_intensity = smoothstep(0.05, 0.05 + specular_smoothness, spec_intensity);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, agitation * reflectiveness) * spec_intensity * litness * brightness;
	
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_amount), shade);
	float rim_intensity = smoothstep(rim_threshold - rim_smoothness/2.0, rim_threshold + rim_smoothness/2.0, rim_dot);
	float rim_value = agitation * reflectiveness;
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, rim_value) * rim_intensity * litness * (1.0 - spec_intensity) * brightness;
}


