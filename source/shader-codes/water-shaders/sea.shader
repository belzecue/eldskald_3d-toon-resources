// This shader was initially done by Miziziziz (https://pastebin.com/t03zpvPN),
// who adapted it from Harry Alisavakis's Unity version
// (https://halisavakis.com/my-take-on-shaders-stylized-water-shader/) 
// I added the waves and moving texture.

shader_type spatial;
render_mode depth_draw_always;

uniform vec4 water_color : hint_color = vec4(1.0);
uniform vec2 texture_movement = vec2(0.0, 1.0);
uniform float texture_displacement = 0.1;
uniform vec2 displacement_scale = vec2(1,1);

uniform vec4 edge_color : hint_color = vec4(1.0);
uniform vec2 edge_noise_scale = vec2(1,1);
uniform float edge_smoothness = 0.05;
uniform float edge_max_threshold = 0.5;
uniform float edge_displacement = 0.6;
uniform float near = 0.15;
uniform float far = 300.0;

uniform float first_wave_height;
uniform float first_wave_length;
uniform vec2 first_wave_velocity = vec2(0.0, 1.0);
uniform float sec_wave_height;
uniform float sec_wave_length;
uniform vec2 sec_wave_velocity = vec2(1.0, 0.0);

uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);

uniform sampler2D water_texture : hint_white;
uniform sampler2D edge_noise : hint_white;
uniform sampler2D texture_noise : hint_white;



// This function turns distances from depth texture into linear system.
float linearize(float c_depth) {
	c_depth = 2.0 * c_depth - 1.0;
	return near * far / (far + c_depth * (near - far));
}

// Fragment function deals with edge foams and water texture.
void fragment() {
	
	// These calculate the distance between the water and whatever's behind it,
	// exactly at the pixel we are looking at with the depth texture. Because we
	// use it, we are sent to the transparent pipeline, meaning the sea doesn't
	// appear behind other transparent objects.
	float zdepth = linearize(texture(DEPTH_TEXTURE, SCREEN_UV).x);
	float zpos = linearize(FRAGCOORD.z);
	float diff = zdepth - zpos;
	
	// These randomize the difference calculated previously using the displacement
	// texture and amount.
	vec2 edge_displ = texture(edge_noise, UV / edge_noise_scale - TIME / 14.0).rg;
	edge_displ = ((edge_displ * 2.0) - 1.0) * edge_displacement;
	diff += edge_displ.x;
	
	// If the final difference with displacement is smaller than the max threshold,
	// we paint the pixel with the edge color.
	vec2 tex_displ = texture(texture_noise, UV / displacement_scale + TIME / 60.0).rg;
	tex_displ = (2.0 * tex_displ - 1.0) * texture_displacement;
	vec4 main_color = water_color * texture(water_texture, UV + TIME * texture_movement + tex_displ);
	float smoothness = smoothstep(edge_max_threshold, edge_max_threshold + edge_smoothness, diff);
	vec4 col = mix(edge_color, main_color, smoothness);
	ALBEDO = col.rgb;
	ALPHA = col.a;
}



// Vertex function deals with the waves.
void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
	
	// These project the vertex coordinates into the wave's direction so we
	// can know its position in the wave.
	vec2 coords = (WORLD_MATRIX * vec4(VERTEX, 1.0)).xz;
	float first_wave = dot(normalize(first_wave_velocity), coords);
	float sec_wave = dot(normalize(sec_wave_velocity), coords);
	
	// Add time and wave length.
	first_wave = (first_wave + TIME * length(first_wave_velocity)) / first_wave_length;
	sec_wave = (sec_wave + TIME * length(sec_wave_velocity)) / sec_wave_length;
	
	// Apply the wave effect.
	VERTEX += NORMAL * (first_wave_height * sin(first_wave) + sec_wave_height * sin(sec_wave));
}



void light() {
	vec3 litness = smoothstep(0.0, 0.05, dot(NORMAL, LIGHT)) * ATTENUATION;
	DIFFUSE_LIGHT += ALBEDO * LIGHT_COLOR * litness;
}


