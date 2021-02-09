// Albedo Pass, Deferred Rendering Pixel-Art.
//
// Uses a  single color palette file and makes sure all colors
// rendered come from this file. Decrease the resolution, stretch
// the screen, turn off anti-aliasing and avoid color interpolation
// from your other shaders.
shader_type spatial;
render_mode unshaded, ambient_light_disabled;



// Albedo. If you tick use_color, it will use the color variable
// as its albedo at all UVs. On deffered rendering, this is just
// an unshaded material. Lighting is handled on the other pass.
uniform sampler2D albedo: hint_albedo;
uniform vec4 albedo_color: hint_color = vec4(1.0);

void fragment() {
	if (albedo_color == vec4(1.0)) {
		ALBEDO = texture(albedo, UV).rgb;
	}
	else {
		ALBEDO = albedo_color.rgb;
	}
}


