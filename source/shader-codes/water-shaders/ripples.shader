// Ripples shader. It's just a geometry modifying shader with base toon lighting.
// It's made to work with ripple-mesh.obj, but you can make variations with more
// segments if you want, just make sure to keep it in a bidimensional ring shape
// with the outer side with a radius of 1 unit.
shader_type spatial;
render_mode depth_draw_always;


uniform vec4 color: hint_color;
uniform sampler2D fade_curve;
uniform float speed;
uniform float ripple_width;
uniform float phase;
uniform float size;



void vertex() {
	float time = mod(phase + TIME * speed, 1.0);
	if (length(VERTEX.xz) < 0.99) {
		VERTEX.xz = normalize(VERTEX.xz) * time * (size - ripple_width * texture(fade_curve, vec2(time, 0.0)).r);
	}
	else {
		VERTEX.xz = VERTEX.xz * time * size;
	}
}



void fragment() {
	ALBEDO = color.rgb;
	ALPHA = color.a;
}

void light() {
	vec3 litness = smoothstep(0.0, 0.05, dot(NORMAL, LIGHT)) * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * litness;
}
