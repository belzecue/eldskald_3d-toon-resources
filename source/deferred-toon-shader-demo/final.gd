extends Viewport

export (float, 1, 16, 0.001) var quality
export (NodePath) var viewport



func _on_FinalViewport_size_changed():
	get_node(viewport).size = self.size

