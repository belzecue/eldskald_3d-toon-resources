// Too flames shader. You put normal flames on a separate Viewport with
// transparent background outside the scene and put its output on texture_albedo.
// It reads the flames and applies an outline to them. This whole thing has
// to go on a flat plane mesh. Using Viewports make this shader a little
// costlier. You can have one Viewport being printed onto more than one
// of these shaders to save processing. And of course, the higher the
// Viewport's size, the costlier it will be.
shader_type spatial;
render_mode depth_draw_alpha_prepass, ambient_light_disabled;

uniform sampler2D texture_albedo : hint_albedo;
uniform float grow;
uniform float emission;
uniform float outline_width;
uniform vec4 outline_color: hint_color;

varying vec2 width;



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



void fragment() {
	vec2 left_up = vec2(-1.0, -1.0)*width;
	vec2 right_up = vec2(1.0, -1.0)*width;
	vec2 right_down = vec2(1.0, 1.0)*width;
	vec2 left_down = vec2(-1.0, 1.0)*width;
	
	vec3 color = texture(texture_albedo, UV).rgb;
	float alpha = texture(texture_albedo, UV).a;
	
	// Checks if the current pixel is in the border and outlines it.
	if (alpha > 0.0) {
		float lu_a = texture(texture_albedo, UV + left_up).a == 0.0 ? 1.0 : 0.0;
		float ru_a = texture(texture_albedo, UV + right_up).a == 0.0 ? 1.0 : 0.0;
		float rd_a = texture(texture_albedo, UV + right_down).a == 0.0 ? 1.0 : 0.0;
		float ld_a = texture(texture_albedo, UV + left_down).a == 0.0 ? 1.0 : 0.0;
		
		float is_border = lu_a + ru_a + rd_a + ld_a > 0.0 ? 1.0 : 0.0;
		color += (outline_color.rgb - color) * is_border;
	}
	
	ALBEDO = color;
	ALPHA = alpha;
	EMISSION = color * emission;
}


