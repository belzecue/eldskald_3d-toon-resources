extends MeshInstance

onready var n: int = 1

var colors = [  Color("000000"), # Black, dark (Black)
				Color("555555"), # Black, light (Dark gray)
				Color("0000aa"), # Blue, dark
				Color("5555ff"), # Blue, light
				Color("00aa00"), # Green, dark
				Color("55ff55"), # Green, light
				Color("00aaaa"), # Cyan, dark
				Color("55ffff"), # Cyan, light
				Color("aa0000"), # Red, dark
				Color("ff5555"), # Red, light
				Color("aa00aa"), # Purple, dark 
				Color("ff55ff"), # Purple, light
				Color("aa5500"), # Yellow, dark (Brown)
				Color("ffff55"), # Yellow, light
				Color("aaaaaa"), # White, dark (Light gray)
				Color("ffffff")  # White, light (White)
			]

func _on_Timer_timeout():
	n = 1 + n%14
	get_surface_material(0).set_shader_param("albedo_color", colors[n])
	$Timer.start()
