// Albedo Pass, Deferred Rendering Pixel-Art.
//
// Uses a  single color palette file and makes sure all colors
// rendered come from this file. Decrease the resolution, stretch
// the screen, turn off anti-aliasing and avoid color interpolation
// from your other shaders.
shader_type spatial;
render_mode unshaded;



// Albedo. If you tick use_color, it will use the color variable
// as its albedo at all UVs. On deffered rendering, this is just
// an unshaded material. Lighting is handled on the other pass.
uniform sampler2D albedo;

void fragment() {
	ALBEDO = texture(albedo, UV).rgb;
}


