tool
extends MeshInstance

export (Vector2) var wind setget set_wind
export (float) var resistance setget set_resistance
export (float) var interval setget set_interval
export (float) var height_offset setget set_height_offset
export (String, "Linear", "Quadratic") var deformation_type = "Linear" setget set_deformation_type
export (float) var var_intensity setget set_var_intensity
export (float) var var_frequency setget set_var_frequency
export (CurveTexture) var wind_var_curve setget set_wind_var_curve

export (Array, int) var secondary_set_of_surfaces

export (Vector2) var wind_sec setget set_wind_sec
export (float) var resistance_sec setget set_resistance_sec
export (float) var interval_sec setget set_interval_sec
export (float) var height_offset_sec setget set_height_offset_sec
export (String, "Linear", "Quadratic") var deformation_type_sec = "Linear" setget set_deformation_type_sec
export (float) var var_intensity_sec setget set_var_intensity_sec
export (float) var var_frequency_sec setget set_var_frequency_sec
export (CurveTexture) var wind_var_curve_sec setget set_wind_var_curve_sec



func set_property_in_all_materials(property: String, value_1, value_2):
	for i in self.get_surface_material_count():
		if i in secondary_set_of_surfaces:
			self.get_surface_material(i).set_shader_param(property, value_2)
			self.get_surface_material(i).next_pass.set_shader_param(property, value_2)
		else:
			self.get_surface_material(i).set_shader_param(property, value_1)
			self.get_surface_material(i).next_pass.set_shader_param(property, value_1)

func set_everything():
	set_property_in_all_materials("wind", wind, wind_sec)
	set_property_in_all_materials("resistance", resistance, resistance_sec)
	set_property_in_all_materials("interval", interval, interval_sec)
	set_property_in_all_materials("height_offset", height_offset, height_offset_sec)
	set_property_in_all_materials("quadratic_deformation", deformation_type == "Quadratic",
														   deformation_type_sec == "Quadratic")
	set_property_in_all_materials("var_intensity", var_intensity, var_intensity_sec)
	set_property_in_all_materials("var_frequency", var_frequency, var_frequency_sec)
	set_property_in_all_materials("wind_var_curve", wind_var_curve, wind_var_curve_sec)
	set_property_in_all_materials("seed", Vector2(translation.x, translation.z),
										  Vector2(translation.x, translation.z))
	
#	var deform_bool
#	match deformation_type:
#		"Linear":
#			deform_bool = false
#		"Quadratic":
#			deform_bool = true
#	match deformation_type_sec:
#		"Linear":
#			set_property_in_all_materials("quadratic_deformation", deform_bool, false)
#		"Quadratic":
#			set_property_in_all_materials("quadratic_deformation", deform_bool, true)



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

func set_deformation_type(new_value: String):
	deformation_type = new_value
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

func set_wind_sec(new_value: Vector2):
	wind_sec = new_value
	set_everything()

func set_resistance_sec(new_value: float):
	resistance_sec = new_value
	set_everything()

func set_interval_sec(new_value: float):
	interval_sec = new_value
	set_everything()

func set_height_offset_sec(new_value: float):
	height_offset_sec = new_value
	set_everything()

func set_deformation_type_sec(new_value: String):
	deformation_type_sec = new_value
	set_everything()

func set_var_intensity_sec(new_value: float):
	var_intensity_sec = new_value
	set_everything()

func set_var_frequency_sec(new_value: float):
	var_frequency_sec = new_value
	set_everything()

func set_wind_var_curve_sec(new_value: CurveTexture):
	wind_var_curve_sec = new_value
	set_everything()





