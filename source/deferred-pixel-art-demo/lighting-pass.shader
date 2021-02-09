// Lighting Pass, Deferred Rendering Pixel-Art
//
// This part deals with light. It uses the red color to indicate what
// is illuminated and green to indicate what has specular.
shader_type spatial;
render_mode ambient_light_disabled;



// These are the parameters for the shader.
// You can turn them off by maxing out or minimizing the thresholds.
uniform float shade_threshold: hint_range(-1.0, 1.0, 0.001) = 0.0;
uniform float specular_threshold: hint_range(0.0, 1.0, 0.001) = 0.5;
uniform float specular_glossiness: hint_range(1.0, 100.0, 0.1) = 15.0;

void light() {
	vec3 diffuse = vec3(0.0);
	
	// Checks if the point is being lit.
	diffuse.r = step(shade_threshold, dot(LIGHT, NORMAL))*step(0.5, ATTENUATION.r)*0.1;
	
	// Checks if the point is on the specular zone or not.
	vec3 half = normalize(LIGHT + VIEW);
	float specular = pow(dot(half, NORMAL), specular_glossiness*specular_glossiness);
	diffuse.g = step(specular_threshold, specular)*0.1;
	
	// In this method, we can account for more than one light source.
	DIFFUSE_LIGHT += diffuse;
}




