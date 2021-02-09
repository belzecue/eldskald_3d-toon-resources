// Final Composition
//
// This will read from both camera feeds and render the final image.
shader_type canvas_item;

uniform vec2 resolution;
uniform sampler2D main;
uniform sampler2D lighting;

void fragment() {
	vec2 coords = floor(UV*resolution);
	vec3 main_color = texture(main, UV).rgb;
	vec2 light = texture(lighting, UV).rg;
	vec3 color = main_color;
	
	// Checks for shadows
	color += (vec3(0.0) - color)*step(light.x, 0.005)*mod(coords.x + coords.y, 2);
	
	// Checks for specular
	color += (vec3(1.0) - color)*step(0.005, light.y)*step(0.005, light.x)*mod(coords.x + coords.y, 2);
	
	COLOR = vec4(color, 1.0);
}


