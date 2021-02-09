// Lighting Pass, Deferred Rendering Toon Shader
//
// This part deals with light. It uses the red color to indicate what
// is illuminated, green to indicate what has specular and blue to.
// indicate what has rim lighting.
shader_type spatial;
render_mode ambient_light_disabled;



// These are the parameters for the shader.
// You can turn them off by maxing out or minimizing the thresholds.
uniform float shade_threshold: hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform bool use_specular = true;
uniform float specular_threshold: hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float specular_glossiness: hint_range(1.0, 100.0, 0.1) = 15.0;
uniform bool use_rim = true;
uniform float rim_amount: hint_range(0.0, 1.0, 0.001) = 0.7;
uniform float rim_threshold: hint_range(0.0, 1.0, 0.001) = 0.2;

// Constants to smooth the edges between darkened or lightened zones
// to make them less jagged. If you want bodies with different sizes
// of smoothness, make those values uniforms.
const float sha_smooth = 0.015;
const float spe_smooth = 0.050;
const float rim_smooth = 0.020;



void light() {
	vec3 diffuse = vec3(0.0);
	
	// Shading.
	float is_lit = smoothstep(shade_threshold - sha_smooth, shade_threshold + sha_smooth, dot(LIGHT, NORMAL));
	float attenuation = clamp(2.0*(ATTENUATION.r - 0.5) + 0.5, 0.0, 1.0);
	diffuse.r = is_lit*ATTENUATION.r*0.1;
	
	// Specular reflection.
	if (use_specular) {
		vec3 half = normalize(LIGHT + VIEW);
		float specular = pow(dot(half, NORMAL), specular_glossiness*specular_glossiness);
		diffuse.g = smoothstep(specular_threshold - spe_smooth, specular_threshold + spe_smooth, specular)*0.1;
	}
	
	// Rim lighting.
	if (use_rim) {
		float rim = (1. - dot(VIEW, NORMAL))*pow(dot(LIGHT, NORMAL), rim_threshold);
		diffuse.b = smoothstep(rim_amount - rim_smooth, rim_amount + rim_smooth, rim)*0.1;
	}
	
	// Adding up to account for multiple light sources.
	DIFFUSE_LIGHT += diffuse;
}