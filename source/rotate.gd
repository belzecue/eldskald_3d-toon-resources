extends MeshInstance

func _process(delta):
	self.rotation_degrees.y += delta*20
