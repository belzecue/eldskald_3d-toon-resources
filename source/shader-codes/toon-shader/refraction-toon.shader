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
// The texture map uses the red channel for the specular value, green for amount
// and blue for smoothness.
uniform float specular : hint_range(0,1) = 0.5;
uniform float specular_amount : hint_range(0,1) = 0.5;
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

// Ambient occlusion from base code.
uniform float ao_light_affect: hint_range(0,1) = 0.0;
uniform sampler2D ao_map : hint_white;

// Anisotropy from base code.
uniform float anisotropy_ratio: hint_range(-1,1) = 0.0;
uniform sampler2D anisotropy_flowmap : hint_aniso;

// Refraction from base code.
uniform float refraction : hint_range(-16,16) = 0.00;
const vec4 refraction_texture_channel = vec4(1.0, 0.0, 0.0, 0.0); // Refraction channel is set to red.
uniform sampler2D texture_refraction;

// UV scale and offset from base code.
uniform vec2 uv_scale = vec2(1,1);
uniform vec2 uv_offset = vec2(0,0);



// Vertex function to deal with UV scale and offset, straight out of base code.
void vertex() {
	UV = UV * uv_scale.xy + uv_offset.xy;
}



void fragment() {
	ALBEDO = albedo.rgb * texture(texture_albedo, UV).rgb;
	ROUGHNESS = roughness * texture(texture_surface, UV).r;
	METALLIC = metallic * texture(texture_surface, UV).g;
	
	// Emission, straight out of base code with additive mode.
	EMISSION = (emission.rgb + texture(texture_emission, UV).rgb) * emission_energy;
	
	// Ambient occlusion, straight out of base code on the red channel.
	AO = texture(ao_map, UV).r;
	AO_LIGHT_AFFECT = ao_light_affect;
	
	// Refraction, straight out of base code.
	vec3 normal = NORMAL;
	vec2 ref_ofs = SCREEN_UV - normal.xy * dot(texture(texture_refraction, UV), refraction_texture_channel) * refraction;
	float ref_amount = 1.0 - albedo.a * texture(texture_albedo, UV).a;
	EMISSION += textureLod(SCREEN_TEXTURE, ref_ofs, 0.0).rgb * ref_amount;
	ALBEDO *= 1.0 - ref_amount;
	ALPHA = 1.0;
}



const float PI = 3.14159265358979323846;

void light() {
	// Let's start by incorporating specular and rim textures. Pay attention to
	// the channels and what each value does.
	float spec_value = specular * texture(texture_specular, UV).r;
	float spec_gloss = pow(2.0, 8.0 * (1.0 - specular_amount * texture(texture_specular, UV).g));
	float spec_smooth = specular_smoothness * texture(texture_specular, UV).b;
	float rim_value = rim * texture(texture_rim, UV).r;
	float rim_width = rim_amount * texture(texture_rim, UV).g;
	float rim_smooth = rim_smoothness * texture(texture_rim, UV).b;
	
	// Lighting part. We smoothstep the dot product for each band then interpolate the sum
	// between the lighting value and 1. Mess with the lighting uniforms to see.
	float shade = dot(NORMAL, LIGHT);
	float dark_shade = smoothstep(0.0, lighting_smoothness, shade);
	float half_shade = smoothstep(lighting_half_band, lighting_half_band + lighting_smoothness, shade);
	vec3 litness = (dark_shade/2.0 + half_shade/2.0) * ATTENUATION;
	DIFFUSE_LIGHT.r += ALBEDO.r * LIGHT_COLOR.r * mix(lighting, 1.0, litness.r);
	DIFFUSE_LIGHT.g += ALBEDO.g * LIGHT_COLOR.g * mix(lighting, 1.0, litness.g);
	DIFFUSE_LIGHT.b += ALBEDO.b * LIGHT_COLOR.b * mix(lighting, 1.0, litness.b);
	
	// Specular part. We use the Blinn-Phong specular calculations with a smoothstep
	// function to toonify. Mess with the specular uniforms to see what each one does.
	// It also deals with anisotropy.
	vec3 aniso_dir = (texture(anisotropy_flowmap, UV).rgb * 2.0 - 1.0);
	vec3 half = normalize(VIEW + LIGHT);
	float aniso = max(0, sin(dot(normalize(NORMAL + aniso_dir), half) * PI));
	float spec = mix(dot(NORMAL, half), aniso, anisotropy_ratio * texture(anisotropy_flowmap, UV).a);
	float spec_intensity = pow(spec, spec_gloss * spec_gloss);
	spec_intensity = smoothstep(0.05, 0.05 + spec_smooth, spec_intensity);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, spec_value) * spec_intensity * litness;
	
	// Rim part. We use the view and normal vectors only to find out if we're looking
	// at a pixel from the edge of the object or not. We add the final value to specular
	// light values so that Godot treats it as specular.
	float rim_dot = 1.0 - dot(NORMAL, VIEW);
	float rim_threshold = pow((1.0 - rim_width), shade);
	float rim_intensity = smoothstep(rim_threshold - rim_smooth/2.0, rim_threshold + rim_smooth/2.0, rim_dot);
	SPECULAR_LIGHT += mix(vec3(0.0), LIGHT_COLOR, rim_value) * rim_intensity * litness;
}

