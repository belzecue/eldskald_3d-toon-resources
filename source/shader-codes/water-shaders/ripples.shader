shader_type spatial;
render_mode depth_draw_alpha_prepass;



// For the best results, use the same color as the water.
uniform vec4 color: hint_color = vec4(1.0);
uniform float speed = 0.2;
uniform float ripple_width = 0.01;
uniform float ripple_space = 0.15;
uniform float ripple_smoothing = 0.005;
uniform float fade = 3.0;
uniform float brightness: hint_range(0,1) = 0.1;



void fragment() {
	// We calculate the distance we are from the center and use that value with
	// a smoothstep to decide what is or is not a ripple.
	float dist = length(UV - vec2(0.5));
	float pos = mod(dist - TIME * speed, ripple_space + ripple_width);
	float is_wave = smoothstep(ripple_width, ripple_width + ripple_smoothing, pos);
	is_wave -= smoothstep(ripple_space + ripple_width - ripple_smoothing, ripple_space + ripple_width, pos);
	is_wave = clamp(1.0 - is_wave - fade * dist, 0.0, 1.0);
	
	// Then, we use the alpha channel to show the ripples.
	ALBEDO = color.rgb;
	ALPHA = color.a * is_wave;
}



void light() {
	DIFFUSE_LIGHT += ALBEDO.rgb * LIGHT_COLOR * ATTENUATION;
	
	// We always put specular in it. Set brightness to zero for no specular.
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, brightness) * ATTENUATION;
}

