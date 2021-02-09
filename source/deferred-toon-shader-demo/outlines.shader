// Outlines, Deferred Toon Shader
//
// Roystan's tutorial on outlines (https://roystan.net/articles/outline-shader.html)
// adapted to Godot's environment. To get access to the depth, view and normals buffer
// on a 2D shader, we render them on separate viewports and sample them as uniforms,
// which also allows us to make our own normals buffer, which is unavailable on Godot's
// shading language on 3.x version.
shader_type canvas_item;



// Outline settings. Color and thickness are obvious. Sensitivies are used how big
// the operators bust be to detect an edge. Thus, the smaller the number, the easiest
// it detects out outlines.
uniform vec4 outline_color: hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform int outline_thickness: hint_range(1, 10) = 1;
uniform float distance_sensitivity;
uniform float normals_sensitivity;
uniform float forced_sensitivity;

// The custom buffers turned into viewports are sampled here.
uniform sampler2D distances;
uniform sampler2D normals;
uniform sampler2D views;
uniform sampler2D forced;



void fragment() {
	vec3 normal = (texture(normals, SCREEN_UV).xyz - vec3(0.5))*2.0;
	vec3 view = (texture(views, SCREEN_UV).xyz - vec3(0.5))*2.0;
	float depth = texture(distances, SCREEN_UV).x + step(texture(distances, SCREEN_UV).x, 0.0001);
	
	// This shold be 0 when there is no outline on the current pixel or
	// 1 or more when there is. We'll use it later as this pixel's alpha.
	float end = 0.0;
	
	// To use the Roberts cross operator, we define these to later add to the
	// current UVs to make the code lines shorter. Don't forget that due to how
	// the Roberts Cross operator works, increasing thickness should increase the
	// operator, and thus you should use higher sensitivities with thicker lines.
	vec2 top_left = vec2(-1.*ceil(float(outline_thickness)/2.), -1.*floor(float(outline_thickness)/2.))*SCREEN_PIXEL_SIZE;
	vec2 top_right = vec2(-1.*ceil(float(outline_thickness)/2.), ceil(float(outline_thickness)/2.))*SCREEN_PIXEL_SIZE;
	vec2 bot_left = vec2(floor(float(outline_thickness)/2.), -1.*floor(float(outline_thickness)/2.))*SCREEN_PIXEL_SIZE;
	vec2 bot_right = vec2(floor(float(outline_thickness)/2.), ceil(float(outline_thickness)/2.))*SCREEN_PIXEL_SIZE;
	
	
	
	// Calculating the Roberts cross operator on the depth. We multiply everything
	// by 100 to increase the operator and use big numbers on our sensitivities
	// just for aesthetic purposes.
	float top_left_d = (1.0 - texture(distances, SCREEN_UV + top_left).x)*100.0;
	float top_right_d = (1.0 - texture(distances, SCREEN_UV + top_right).x)*100.0;
	float bot_left_d = (1.0 - texture(distances, SCREEN_UV + bot_left).x)*100.0;
	float bot_right_d = (1.0 - texture(distances, SCREEN_UV + bot_right).x)*100.0;
	
	// We are not taking the square root like usual to make the processing
	// lighter, we will square out our sensitivity uniforms instead.
	float operator_d = pow((top_left_d - bot_right_d)/float(outline_thickness), 2);
	operator_d += pow((top_right_d - bot_left_d)/float(outline_thickness), 2);
	
	// This 1 - N dot V and depth factors are to here to fix artifacts, as
	// shown in Roystan's tutorial. We are doing 1.001 instead of 1 because
	// Godot behaves weirdly when this value gets zeroed out.
	end += step(distance_sensitivity*(1.001 - dot(normal, view)), operator_d*depth);
	
	
	
	// Calculating the Roberts cross operator on the normals.
	vec3 top_left_n = (texture(normals, SCREEN_UV + top_left).xyz - vec3(0.5))*2.0;
	vec3 top_right_n = (texture(normals, SCREEN_UV + top_right).xyz - vec3(0.5))*2.0;
	vec3 bot_left_n = (texture(normals, SCREEN_UV + bot_left).xyz - vec3(0.5))*2.0;
	vec3 bot_right_n = (texture(normals, SCREEN_UV + bot_right).xyz - vec3(0.5))*2.0;
	
	// No square roots here too, square out the sensitivity uniform. Multiplying
	// the operator by 100 squared here for the same reason we multiplied
	// the distance operator factors by 100.
	float operator_n = dot(top_left_n - bot_right_n, top_left_n - bot_right_n)*10000.0;
	operator_n += dot(top_right_n - bot_left_n, top_right_n - bot_left_n)*10000.0;
	
	// Using a depth factor here to fix artifacts on curved surfaces seen
	// from afar.
	end += step(normals_sensitivity, operator_n*depth);
	
	
	
	// Lastly, the Roberts cross operator on the forced outlines viewport.
	// We'll use this viewport to cast outlines in places where there are no
	// edges by distance or by normal, like patterns drawn on surfaces.
	vec3 top_left_f = texture(forced, SCREEN_UV + top_left).rgb;
	vec3 top_right_f = texture(forced, SCREEN_UV + top_right).rgb;
	vec3 bot_left_f = texture(forced, SCREEN_UV + bot_left).rgb;
	vec3 bot_right_f = texture(forced, SCREEN_UV + bot_right).rgb;
	float operator_f = dot(top_left_f - bot_right_f, top_left_f - bot_right_f)*10000.0;
	operator_f += dot(top_right_f - bot_left_f, top_right_f - bot_left_f)*10000.0;
	end += step(forced_sensitivity, operator_f*depth);
	
	
	
	// Final results.
	COLOR = outline_color;
	COLOR.a = end;
}
