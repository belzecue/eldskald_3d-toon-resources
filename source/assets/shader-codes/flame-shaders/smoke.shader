// Toon smoke shader.
// It's a simplified version of the refraction shader on fragment and light,
// with an added vertex function to morph its shape with time.
shader_type spatial;
render_mode depth_draw_always;

uniform float lighting : hint_range(0,1) = 0.0;
uniform float lighting_half_band : hint_range(0,1) = 0.25;
uniform float lighting_smoothness : hint_range(0,1) = 0.02;

varying float alpha;



// We need this to pass the alpha value to the light pass.
void vertex() {
	alpha = COLOR.a;
}



void fragment() {
	// Reading from screen to ignore other particles.
	vec4 screen = texture(SCREEN_TEXTURE, SCREEN_UV);
	ALBEDO = mix(screen.rgb, COLOR.rgb, COLOR.a);
}



void light() {
	// Lighting part of the base toon shader. No specular or rim lighting added.
	// Just copy them directly from the base shader code if you want smoke with them.
	float shade = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float dark_shade = smoothstep(0.0, lighting_smoothness, shade);
	float half_shade = smoothstep(lighting_half_band, lighting_half_band + lighting_smoothness, shade);
	vec3 litness = (dark_shade/2.0 + half_shade/2.0) * ATTENUATION;
	DIFFUSE_LIGHT.r += ALBEDO.r * LIGHT_COLOR.r * mix(lighting, 1.0, litness.r);
	DIFFUSE_LIGHT.g += ALBEDO.g * LIGHT_COLOR.g * mix(lighting, 1.0, litness.g);
	DIFFUSE_LIGHT.b += ALBEDO.b * LIGHT_COLOR.b * mix(lighting, 1.0, litness.b);
	DIFFUSE_LIGHT = mix(ALBEDO, DIFFUSE_LIGHT, alpha); // This last line is to add transparency.
}


