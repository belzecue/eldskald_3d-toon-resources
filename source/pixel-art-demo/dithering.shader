// Dithering Post-Process Shader
//
// It reads the screen in search of colors tinted with either shade or specular
// tints and turns them into chess-like pattern with its untinted color and
// the shade or the specular color.
shader_type canvas_item;
render_mode unshaded;



// Set here the file you used for all the model textures, your color palette.
// The palette_size is its size in matrix coordinates, so a (4,4) size would
// mean the file has 16 colors arranged in a 4 by 4 matrix of colored squares. 
uniform sampler2D color_palette;
uniform vec2 palette_size;

// Coordinates of the colors of the shade and specular colors.
// Top left color of the palette is 1,1.
uniform vec2 shade_color;
uniform vec2 specular_color;

// Constant that tints the shade and specular zones, used to recognize them.
// Must be equal to the one in limited-colors.shader of the same name.
const vec3 tint = vec3(0.1);



// This function takes color coordinates and return the corresponding
// color from the color_palette file.
vec4 color(vec2 coords) {
	return texture(color_palette, (coords - vec2(.5))/palette_size);
}



void fragment() {

	// Catches the color from the pixel's center
	vec2 coords = floor(UV/TEXTURE_PIXEL_SIZE);
	vec4 cur_color = texture(TEXTURE, (coords + vec2(0.5))*TEXTURE_PIXEL_SIZE);

	// Reads the current color and returns its coordinates in the color palette texture file.
	// The third coordinate is 0 for no modifications, 1 for shade tinted, 2 for specular tinted.
	vec3 color_coords = vec3(0.);
	for (float j = 1.; j <= palette_size.y; j += 1.) {
		for (float i = 1.; i <= palette_size.x; i += 1.) {

			vec4 li_color = color(vec2(i,j));
			vec4 sh_color = li_color - vec4(tint, .0);
			vec4 sp_color = li_color + vec4(tint, .0);

			color_coords += vec3(i,j,0.)*step(length(cur_color - li_color), 0.05);
			color_coords += vec3(i,j,1.)*step(length(cur_color - sh_color), 0.15);
			color_coords += vec3(i,j,2.)*step(length(cur_color - sp_color), 0.15);
		}
	}
	
	// Correcting the light tint
	if (color_coords.z == 0.) {
		COLOR = color(color_coords.xy);
	}
	
	// Correcting the shade tint
	if (color_coords.z == 1.) {
		COLOR = color(shade_color) + (color(color_coords.xy) - color(shade_color))*mod(coords.x + coords.y, 2);
	}

	// Correcting the specular tint
	else if (color_coords.z == 2.) {
		COLOR = color(specular_color) + (color(color_coords.xy) - color(specular_color))*mod(coords.x + coords.y, 2);
	}
}


