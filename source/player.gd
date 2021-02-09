extends KinematicBody

export (float) var speed

onready var velocity = Vector3.ZERO
onready var input_dir = Vector2.ZERO

export (float, 0.1, 5) var mouse_sensitivity
export (bool) var invert_y_axis
onready var camera = $Camera



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	OS.center_window()



# Moving the player along the XZ plane with WASD.
func _physics_process(_delta):
	
	# Get the directional inputs
	input_dir.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	
	# Moving the player
	velocity = input_dir.normalized()
	velocity = -self.transform.basis.z*velocity.y + self.transform.basis.x*velocity.x
	velocity = move_and_slide(velocity*speed)



# Moving the camera with the mouse
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		# Let's only spin the camera in the vertical axis and move the whole player on the
		# horizontal axis, because if the player looks up or down, the camera's x axis will
		# change and no longer represent rotations on the horizon plane.
		self.rotate_y(-deg2rad(event.relative.x*mouse_sensitivity/5))
		if invert_y_axis:
			camera.rotate_x(deg2rad(event.relative.y*mouse_sensitivity/5))
		else:
			camera.rotate_x(-deg2rad(event.relative.y*mouse_sensitivity/5))
		
		# Prevent the camera from turning upside down.
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
	
	# Releasing or capturing the mouse after clicking.
	if event.is_action("click"):
		if event.is_pressed() and not event.is_echo():
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)





