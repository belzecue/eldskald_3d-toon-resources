// Toon Shader.
//
// Also known as cel shading, this is a technique used to make
// 3D models look like toon animations, used by games such as
// The Wind Waker, Breath of the Wild, Dragon Quest, Ni No Kuni
// and most anime video games.
shader_type spatial;
render_mode ambient_light_disabled, depth_draw_alpha_prepass;



// Albedo. Tick use_color to color the entire model with the
// color instead of the texture file.
uniform sampler2D albedo: hint_albedo;
uniform vec4 albedo_color: hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_color;

void fragment() {
	if (use_color) {
		ALBEDO = albedo_color.rgb;
		ALPHA = albedo_color.a;
	}
	else {
		ALBEDO = texture(albedo, UV).rgb;
		ALPHA = texture(albedo, UV).a;
	}
}



// These are the parameters for the shader.
// You can turn them off by maxing out or minimizing the thresholds.
uniform float shade_threshold: hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform float specular_threshold: hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float specular_glossiness: hint_range(1.0, 100.0, 0.1) = 15.0;
uniform float specular_brightness: hint_range(0.0, 1.0, 0.001) = 0.3;
uniform float rim_amount: hint_range(0.0, 1.0, 0.001) = 0.7;
uniform float rim_threshold: hint_range(0.0, 1.0, 0.001) = 0.2;
uniform float rim_brightness: hint_range(0.0, 1.0, 0.001) = 0.3;

// Constants to tint the colors for shadows, shade, specular and rim
// zones. If you want bodies with different tones, make them uniform.
const vec3 dark_diff = vec3(0.0);
const vec3 light_diff = vec3(1.0);

// Constants to smooth the edges between darkened or lightened zones
// to make them less jagged. If you want bodies with different sizes
// of smoothness, make those values uniforms.
const float sha_smooth = 0.015;
const float spe_smooth = 0.050;
const float rim_smooth = 0.020;



void light() {
	vec3 diffuse = dark_diff;
	
	// Checks if the point is being lit.
	float is_lit = smoothstep(shade_threshold - sha_smooth, shade_threshold + sha_smooth, dot(LIGHT, NORMAL));
	is_lit = min(is_lit, ATTENUATION.r);
	diffuse += (ALBEDO - diffuse)*is_lit;
	
	// Specular reflection.
	vec3 half = normalize(LIGHT + VIEW);
	float specular = pow(dot(half, NORMAL), specular_glossiness*specular_glossiness);
	specular = smoothstep(specular_threshold - spe_smooth, specular_threshold + spe_smooth, specular);
	diffuse += (mix(ALBEDO, light_diff, specular_brightness) - diffuse)*specular*is_lit;
	
	// Rim lighting.
	float rim = (1. - dot(VIEW, NORMAL))*pow(dot(LIGHT, NORMAL), rim_threshold);
	rim = smoothstep(rim_amount - rim_smooth, rim_amount + rim_smooth, rim);
	diffuse += (mix(ALBEDO, light_diff, rim_brightness) - diffuse)*rim*is_lit;
	
	DIFFUSE_LIGHT = mix(ALBEDO, diffuse, 0.6);
}


