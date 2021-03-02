extends RigidBody

export (float) var speed
export (float) var acceleration
export (float, 0, 1) var brake_friction 
export (float) var jump_force
onready var input: Vector3 = Vector3.ZERO
onready var is_jumping: bool = false

export (float, 0.1, 5) var mouse_sensitivity
export (bool) var invert_y_axis
onready var camera: Camera = $Camera



func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	OS.center_window()



# Moving the player along the XZ plane with WASD.
func _physics_process(_delta):
	
	# Get the directional inputs.
	input.z = Input.get_action_strength("move_forward") - Input.get_action_strength("move_back")
	input.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
	var move_input = Vector3(input.x, 0, input.y).normalized()
	move_input = -self.transform.basis.z * move_input.z + self.transform.basis.x * move_input.x
	
	# Accelerating the player.
	if input != Vector3.ZERO:
		physics_material_override.friction = 0
		if linear_velocity.length_squared() < speed * speed:
			add_central_force(move_input * acceleration)
		
		# In this case, we are taking a tangent vector pointing towards
		# the move_input vector so we can accelerate without increasing
		# linear speed above our limit. We double it for better feel.
		elif linear_velocity.angle_to(move_input) != 0:
			var proj_vel = Vector3(linear_velocity.x, 0, linear_velocity.z)
			var dir = move_input - move_input.project(proj_vel)
			add_central_force(dir.normalized() * acceleration * 2)
	
	# Braking the player.
	else:
		physics_material_override.friction = brake_friction
		if linear_velocity.length_squared() > 0.25:
			add_central_force(-linear_velocity.normalized() * acceleration)
	
	# Jumping.
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_jumping:
		is_jumping = true
		apply_central_impulse(jump_force * Vector3.UP)
	if is_jumping:
		
		# If the player lets go of the jump button, let's cut
		# vertical velocity in half.
		if not Input.is_action_pressed("jump"):
			apply_central_impulse(-linear_velocity.project(Vector3.UP) / 2)
			is_jumping = false
		elif linear_velocity.y <= 0:
			is_jumping = false



# GroundMonitor can't detect the player due to its layer, so if
# it detects anything at all, it means the player is standing on it.
func is_on_floor() -> bool:
	return $GroundMonitor.get_overlapping_bodies().size() > 0



# Moving the camera with the mouse.
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





