extends Node

export (Array, NodePath) var sec_pass_camera
export (Array, NodePath) var make_visible

onready var player = get_tree().get_nodes_in_group("player")[0]
onready var player_camera = get_tree().get_nodes_in_group("camera")[0]



func _ready():
	for path in make_visible:
		get_node(path).visible = true
	for path in sec_pass_camera:
		var camera_node = get_node(path)
		camera_node.fov = player_camera.fov
		camera_node.near = player_camera.near
		camera_node.far = player_camera.far



func _process(_delta):
	for path in sec_pass_camera:
		var camera_node = get_node(path)
		camera_node.translation = player.translation
		camera_node.translation += player.transform.basis.xform(player_camera.translation)
		camera_node.rotation_degrees.y = player.rotation_degrees.y
		camera_node.rotation_degrees.x = player_camera.rotation_degrees.x/player.scale.x



func _input(event):
	player._input(event)


