// Pixel Art Shader.
//
// Uses a  single color palette file and makes sure all colors
// rendered come from this file. Decrease the resolution, stretch
// the screen, turn off anti-aliasing and avoid color interpolation
// from your other shaders.
shader_type spatial;
render_mode ambient_light_disabled;



// Albedo. Don't forget that all colors must come from the color palette
// you choose, or the dithering filter will blacken it out. If you tick
// use_color, it will use the color variable as its albedo at all UVs.
uniform sampler2D albedo;
uniform vec4 albedo_color: hint_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform bool use_color;

void fragment() {
	if (use_color) {
		ALBEDO = pow(albedo_color.rgb, vec3(1.0/2.2));
	}
	else {
		ALBEDO = texture(albedo, UV).rgb;
	}
}

// These are the parameters for the shader.
// You can turn them off by maxing out or minimizing the thresholds.
uniform float shade_threshold: hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform float specular_threshold: hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float specular_glossiness: hint_range(1.0, 100.0, 0.1) = 15.0;

// Constant to tint the colors for shade and specular zones.
const vec3 tint = vec3(0.1);



// Light function will designate shade and specular zones.
// Will tint these regions with a specific color that will be
// read by the filter to create the shade and specular colors.
void light() {
	vec3 diffuse = -tint;
	
	// Checks if the point is being lit.
	float is_lit = step(shade_threshold, dot(LIGHT, NORMAL))*step(0.5, ATTENUATION.r);
	diffuse += (vec3(0.) - diffuse)*is_lit;
	
	// Checks if the point is on the specular zone or not.
	vec3 half = normalize(LIGHT + VIEW);
	float specular = pow(dot(half, NORMAL), specular_glossiness*specular_glossiness);
	diffuse += (tint - diffuse)*step(specular_threshold, specular)*is_lit;
	
	// This will break the color palette, but they look decent
	// on the editor. Will be filtered out by the filter node.
	DIFFUSE_LIGHT = pow(ALBEDO + diffuse, vec3(2.2));
}


