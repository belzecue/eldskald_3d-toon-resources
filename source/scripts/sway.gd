tool
extends MeshInstance

export (Vector2) var wind setget set_wind
export (float) var resistance setget set_resistance
export (float) var interval setget set_interval
export (float) var height_offset setget set_height_offset
export (float) var var_intensity setget set_var_intensity
export (float) var var_frequency setget set_var_frequency
export (CurveTexture) var wind_var_curve setget set_wind_var_curve



func set_property_in_all_materials(property: String, value):
	for i in self.get_surface_material_count():
		self.get_surface_material(i).set_shader_param(property, value)
		self.get_surface_material(i).next_pass.set_shader_param(property, value)

func set_everything():
	set_property_in_all_materials("wind", wind)
	set_property_in_all_materials("resistance", resistance)
	set_property_in_all_materials("interval", interval)
	set_property_in_all_materials("height_offset", height_offset)
	set_property_in_all_materials("var_intensity", var_intensity)
	set_property_in_all_materials("var_frequency", var_frequency)
	set_property_in_all_materials("wind_var_curve", wind_var_curve)
	set_property_in_all_materials("seed", Vector2(translation.x, translation.z))



# Setget functions
func set_wind(new_value: Vector2):
	wind = new_value
	set_everything()

func set_resistance(new_value: float):
	resistance = new_value
	set_everything()

func set_interval(new_value: float):
	interval = new_value
	set_everything()

func set_height_offset(new_value: float):
	height_offset = new_value
	set_everything()

func set_var_intensity(new_value: float):
	var_intensity = new_value
	set_everything()

func set_var_frequency(new_value: float):
	var_frequency = new_value
	set_everything()

func set_wind_var_curve(new_value: CurveTexture):
	wind_var_curve = new_value
	set_everything()







