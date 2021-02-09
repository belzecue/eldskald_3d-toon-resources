shader_type spatial;
render_mode unshaded;

uniform vec4 outline_color: hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int outline_thickness: hint_range(1, 10) = 1;

uniform float distance_sensitivity;
uniform float normals_sensitivity;



// This keeps the QuadMesh following the screen at all times.
void vertex() {
	POSITION = vec4(VERTEX, 1.0);
}



// This function returns the distance from the pixel of UV uv+d_uv, where uv
// is the current uv being rendered. Also, depth must be equal to DEPTH_TEXTURE
// and inv must be equal to INV_PROJECTION_MATRIX.
float get_depth(vec2 d_uv, vec2 uv, sampler2D depth, mat4 inv) {
	vec3 ndc = vec3(uv + d_uv, texture(depth, uv + d_uv).x)*2.0 - vec3(1.0);
	vec4 view = inv*vec4(ndc, 1.0);
	return -view.z/view.w/50.0;
}



void fragment() {
	vec3 color = vec3(0.0);
	vec2 size = vec2(1./VIEWPORT_SIZE.x, 1./VIEWPORT_SIZE.y);
	vec2 top_left = vec2(-1.*ceil(float(outline_thickness)/2.), -1.*floor(float(outline_thickness)/2.))*size;
	vec2 top_right = vec2(-1.*ceil(float(outline_thickness)/2.), ceil(float(outline_thickness)/2.))*size;
	vec2 bot_left = vec2(floor(float(outline_thickness)/2.), -1.*floor(float(outline_thickness)/2.))*size;
	vec2 bot_right = vec2(floor(float(outline_thickness)/2.), ceil(float(outline_thickness)/2.))*size;
	
	// We'll use the Roberts cross operator method. First on the depth.
	float top_left_d = get_depth(top_left, SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX)*100.0;
	float top_right_d = get_depth(top_right, SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX)*100.0;
	float bot_left_d = get_depth(bot_left, SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX)*100.0;
	float bot_right_d = get_depth(bot_right, SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX)*100.0;
	float edge_d = pow(top_left_d - bot_right_d, 2) + pow(top_right_d - bot_left_d, 2);
	vec3 normal = normalize((texture(SCREEN_TEXTURE, SCREEN_UV).rgb - vec3(0.5))*2.0);
	float depth = (1.0 - get_depth(vec2(0.0), SCREEN_UV, DEPTH_TEXTURE, INV_PROJECTION_MATRIX));
	depth = clamp(depth, 0.0, 1.0);
	color += (outline_color.rgb - color)*step(pow(distance_sensitivity, 2)*(1.001 - dot(normal,VIEW)), edge_d*depth);
	
	// Now on the normals.
	vec3 top_left_n = (texture(SCREEN_TEXTURE, SCREEN_UV + top_left).rgb - vec3(0.5))*2.0;
	vec3 top_right_n = (texture(SCREEN_TEXTURE, SCREEN_UV + top_right).rgb - vec3(0.5))*2.0;
	vec3 bot_left_n = (texture(SCREEN_TEXTURE, SCREEN_UV + bot_left).rgb - vec3(0.5))*2.0;
	vec3 bot_right_n = (texture(SCREEN_TEXTURE, SCREEN_UV + bot_right).rgb - vec3(0.5))*2.0;
	float edge_n = dot(top_left_n - bot_right_n, top_left_n - bot_right_n);
	edge_n += dot(top_right_n - bot_left_n, top_right_n - bot_left_n);
	edge_n = edge_n*10000.0;
	color += (outline_color.rgb - color)*step(pow(normals_sensitivity, 2), edge_n);
	
	ALBEDO = color;
}


