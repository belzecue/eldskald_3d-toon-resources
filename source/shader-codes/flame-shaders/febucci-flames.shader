// Original shader from (godotshaders.com/shader/2D-fire/), who adapted it from 
// Unity from (https://www.febucci.com/2019/05/fire-shader/).
//
// Adapted for a 3D mesh, adding in the outliner, emission and shape. Put this shader on
// a QuadMesh, Godot's base noise texture on noise_tex and you can use either gradient
// or curve tools on gradient_tex. Shape textures are easy to draw, just experiment
// with it. You can use the shape scale and offsets to move it, and you can also play
// around with the gradient curve to also change the shape.
//
// Because it is actually a 2D image printed on a QuadMesh, it might look bad if the
// camera gets too close to it, especially if you look from above or below. If your
// game has a locked camera distance, like the ones in most 3D JRPGs, RTSs or any
// isometric type of view, this is not a problem. It might be if your game has a 3rd
// person camera controls or is in 1st person. If that is the case, I suggest you use
// Minionsart's flames instead. They look really nice and are completely 3D, but they
// lack the outlines.

shader_type spatial;
render_mode depth_draw_alpha_prepass, ambient_light_disabled;


uniform float outline_width = 2.0;
uniform vec4 outline_color : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform vec4 brighter_color : hint_color = vec4(1.0, 0.8, 0.0, 1.0);
uniform vec4 middle_color : hint_color  = vec4(1.0, 0.56, 0.0, 1.0);
uniform vec4 darker_color : hint_color  = vec4(0.64, 0.2, 0.05, 1.0);
uniform float emission = 0.5;
uniform float grow = 0.1;

uniform vec2 shape_scale = vec2(1.0);
uniform vec2 shape_offset = vec2(0.0);

uniform sampler2D noise_tex;
uniform sampler2D gradient_tex;
uniform sampler2D shape_tex;

varying vec2 width;     // This is information sent from vertex pass to fragment for the outline.



void vertex() {
	// Billboard mode, directly unmodified from spatial to shader conversion.
	MODELVIEW_MATRIX = INV_CAMERA_MATRIX * mat4(CAMERA_MATRIX[0],WORLD_MATRIX[1],vec4(normalize(cross(CAMERA_MATRIX[0].xyz,WORLD_MATRIX[1].xyz)), 0.0),WORLD_MATRIX[3]);
	MODELVIEW_MATRIX = MODELVIEW_MATRIX * mat4(vec4(1.0, 0.0, 0.0, 0.0),vec4(0.0, 1.0/length(WORLD_MATRIX[1].xyz), 0.0, 0.0), vec4(0.0, 0.0, 1.0, 0.0),vec4(0.0, 0.0, 0.0 ,1.0));
	
	// Grow code from spatial to shader conversion, but instead of growing in the normal
	// direction, it moves towards the camera so when viewed from corners when close, it
	// doesn't look displaced to the side away from the camera.
	vec4 view_position = MODELVIEW_MATRIX * vec4(VERTEX, 1.0);
	VERTEX -= normalize(view_position.xyz) * grow;
	
	// Calculates outline width based off of view distance.
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	width = 1.0/VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;
}



// This function detects flame in the given uv coordinates. Make time equal to TIME.
float detect(vec2 uv, float time) {
	float noise_value = texture(noise_tex, uv + vec2(0.0, time)).x;
	vec2 shape_uv = clamp((uv - vec2(0.5)) / shape_scale + vec2(0.5) + shape_offset, vec2(0.0), vec2(1.0));
	float gradient_value = texture(gradient_tex, uv.yx).x * texture(shape_tex, shape_uv).x;
	return step(noise_value, gradient_value);
}



void fragment() {
	float noise_value = texture(noise_tex, UV + vec2(0.0, TIME)).x;
	vec2 shape_uv = clamp((UV - vec2(0.5)) / shape_scale + vec2(0.5) + shape_offset, vec2(0.0), vec2(1.0));
	float gradient_value = texture(gradient_tex, UV.yx).x * texture(shape_tex, shape_uv).x;
	
	float step1 = step(noise_value, gradient_value);
	float step2 = step(noise_value, gradient_value - 0.2);
	float step3 = step(noise_value, gradient_value - 0.4);
	
	vec4 color = outline_color;
	
	// This part we detect the outlines.
	vec2 left_up = UV + vec2(-1.0, -1.0) * width;
	vec2 right_up = UV + vec2(1.0, -1.0) * width;
	vec2 right_down = UV + vec2(1.0, 1.0) * width;
	vec2 left_down = UV + vec2(-1.0, 1.0) * width;
	color.a *= min(detect(left_up, TIME) + detect(left_down, TIME) + detect(right_up, TIME) + detect(right_down, TIME), 1.0);
	
	// This part we color the flames.
	if (step1 == 1.0) {
		vec4 bd_color = mix(brighter_color, darker_color, step1 - step2);
		color = vec4(bd_color);
		color = mix(color, middle_color, step2 - step3);
	}
	
	ALBEDO = color.rgb;
	ALPHA = color.a;
	EMISSION = color.rgb * emission;
}



