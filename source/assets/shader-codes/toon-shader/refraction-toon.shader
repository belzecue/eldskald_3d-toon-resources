// Toon shader with transparency and refraction.
// It has to be separated because assigning a value to alpha automatically puts
// it into the transparency pipeline, causing it to not cast shadows.
shader_type spatial;
render_mode depth_draw_always;

uniform vec4 albedo : hint_color = vec4(1.0);
uniform sampler2D texture_albedo : hint_albedo;

// Roughness and metallic here are only for reflection purposes. The surface
// texture maps the red channel to roughness and the green channel to metallic.
uniform float roughness : hint_range(0,1) = 1.0;
uniform float metallic : hint_range(0,1) = 0.0;
uniform sampler2D texture_surface : hint_white;

// Lighting uniforms. Set a high lighting value to make shaded parts brighter,
// and set the half band to zero to turn it off.
uniform float lighting : hint_range(0,1) = 0.0;
uniform float lighting_half_band : hint_range(0,1) = 0.25;
uniform float lighting_smoothness : hint_range(0,1) = 0.02;

// Specular reflection uniforms. Set specular to zero to turn off the effect.
// The texture map uses the red channel for the specular value, green for glossiness
// and blue for smoothness.
uniform float specular : hint_range(0,1) = 0.5;
uniform float specular_glossiness : hint_range(4,64) = 16;
uniform float specular_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_specular : hint_white;

// Rim lighting uniforms. Set rim to zero to turn off the effect.
// The texture map uses the red channel for the rim value, green for rim amount
// and blue for smoothness.
uniform float rim : hint_range(0,1) = 0.5;
uniform float rim_amount : hint_range(0,1) = 0.2;
uniform float rim_smoothness : hint_range(0,1) = 0.05;
uniform sampler2D texture_rim : hint_white;

// Emission from base code.
uniform vec4 emission : hint_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float emission_energy = 1.0;
uniform sampler2D texture_emission : hint_black_albedo;

// Refraction from base code.
uniform float refraction : hint_range(-16,16) = 0.00;
const vec4 refraction_texture_channel = vec4(1.0, 0.0, 0.0, 0.0); // Refraction channel is set to red.
uniform sampler2D texture_refraction;

// UV1 from base code.
uniform vec3 uv1_scale;
uniform vec3 uv1_offset;



// Vertex function to deal with UV1, straight out of base code.
void vertex() {
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}



void fragment() {
	ALBEDO = albedo.rgb * texture(texture_albedo, UV).rgb;
	ROUGHNESS = roughness * texture(texture_surface, UV).r;
	METALLIC = metallic * texture(texture_surface, UV).g;
	
	// Emission, straight out of base code with additive mode.
	EMISSION = (emission.rgb + texture(texture_emission, UV).rgb) * emission_energy;
	
	// Refraction, straight out of base code.
	vec3 normal = NORMAL;
	vec2 ref_ofs = SCREEN_UV - normal.xy * dot(texture(texture_refraction, UV), refraction_texture_channel) * refraction;
	float ref_amount = 1.0 - albedo.a * texture(texture_albedo, UV).a;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, 0.0).rgb * ref_amount;
	ALBEDO *= 1.0 - ref_amount;
	ALPHA = 1.0;
}



void light() {
	// Lighting part. We smoothstep the dot product for each band then interpolate the sum
	// between the lighting value and 1. Mess with the lighting uniforms to see.
	float shade = clamp(dot(NORMAL, LIGHT), 0.0, 1.0);
	float dark_shade = smoothstep(0.0, lighting_smoothness, shade);
	float half_shade = smoothstep(lighting_half_band, lighting_half_band + lighting_smoothness, shade);
	float litness = dark_shade/2.0 + half_shade/2.0; // We'll use this value on spec and rim to check for shading
	DIFFUSE_LIGHT += ALBEDO * ATTENUATION * LIGHT_COLOR * mix(lighting, 1.0, litness);
	
	// Specular part. We use the Blinn-Phong specular calculations with a smoothstep
	// function to toonify. Mess with the specular uniforms to see what each one does.
	vec3 half = normalize(VIEW + LIGHT);
	float spec_intensity = pow(dot(NORMAL, half), specular_glossiness * specular_glossiness);
	spec_intensity = smoothstep(0.05, 0.05 + specular_smoothness, spec_intensity);
	SPECULAR_LIGHT += ATTENUATION * mix(vec3(0.0), LIGHT_COLOR, specular) * spec_intensity * litness;
	
	// Rim part. We use the view and normal vectors only to find out if we're looking
	// at a pixel from the edge of the object or not. We add the final value to specular
	// light values so that Godot treats it as specular.
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_amount), shade);
	float rim_intensity = smoothstep(rim_threshold - rim_smoothness/2.0, rim_threshold + rim_smoothness/2.0, rim_dot);
	SPECULAR_LIGHT += ATTENUATION * mix(vec3(0.0), LIGHT_COLOR, rim) * rim_intensity * litness;
}


