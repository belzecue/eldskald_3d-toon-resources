extends Viewport

export (Array, NodePath) var viewports

func _on_Viewport_size_changed():
	for path in viewports:
		get_node(path).size = self.size
