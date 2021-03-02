extends KinematicBody

export (float) var _speed
export (float) var _acceleration
export (float) var _jump_force
export (float) var _gravity

onready var input: Vector2 = Vector2.ZERO
onready var velocity: Vector3 = Vector3.ZERO
onready var current_speed: float = 0.0
onready var is_jumping: bool = false

export (float, 0.1, 5) var _mouse_sensitivity
export (bool) var _invert_y_axis

onready var camera: Camera = $Camera



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	OS.center_window()



# Moving the player along the XZ plane with WASD.
func _physics_process(delta):
	
	# Get the directional inputs.
	input.y = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var move_input = Vector3(input.x, 0, input.y).normalized()
	move_input = -self.transform.basis.z * move_input.z + self.transform.basis.x * move_input.x
	
	# Move on the XZ plane.
	current_speed = clamp(current_speed + _acceleration * delta, 0.0, _speed) * move_input.length()
	velocity.x = move_input.x * current_speed
	velocity.z = move_input.z * current_speed
	
	# Gravity.
	velocity.y -= _gravity * delta
	
	# Jumping.
	if is_jumping:
		if not Input.is_action_pressed("jump") and velocity.y > 0:
			velocity.y /= 2
			is_jumping = false
		elif velocity.y < 0 or is_on_floor():
			is_jumping = false
	elif Input.is_action_pressed("jump") and is_on_floor():
		velocity.y = _jump_force
		is_jumping = true
	
	velocity = move_and_slide(velocity, Vector3.UP)



# Moving the camera with the mouse.
func _input(event):
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		
		# Let's only spin the camera in the vertical axis and move the whole player on the
		# horizontal axis, because if the player looks up or down, the camera's x axis will
		# change and no longer represent rotations on the horizon plane.
		self.rotate_y(-deg2rad(event.relative.x * _mouse_sensitivity/5))
		if _invert_y_axis:
			camera.rotate_x(deg2rad(event.relative.y * _mouse_sensitivity/5))
		else:
			camera.rotate_x(-deg2rad(event.relative.y * _mouse_sensitivity/5))
		
		# Prevent the camera from turning upside down.
		camera.rotation_degrees.x = clamp(camera.rotation_degrees.x, -90, 90)
	
	# Releasing or capturing the mouse after clicking.
	if event.is_action("click"):
		if event.is_pressed() and not event.is_echo():
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
