extends KinematicBody

var mouse_sensitivity = 1

var walk_speed = 4
var jump_height = 3.5

var current_speed = walk_speed

var ground_acceleration = 10
var air_acceleration = 1
var acceleration = air_acceleration

var direction = Vector3()
var velocity = Vector3() # Direction with acceleration added
var movement = Vector3() # Velocity with gravity added

var gravity = 9.8
var gravity_vec = Vector3()

var snapped = false
var can_jump = true
var can_move = true

onready var main_cast = $MainCast
onready var hud = $Ui/HUD
onready var zoom_tween = $Zoom
onready var cam = $Head/Cam

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event):
	# Look with the mouse
#	if event is InputEventMouseMotion and can_aim:
#		rotation_degrees.y -= event.relative.x * mouse_sensitivity / 18
#		cursor.translation.z += event.relative.y * mouse_sensitivity / 72
#		cursor.translation.x += event.relative.x * mouse_sensitivity / 72
		
	direction = Vector3()

func _physics_process(delta):
	
	if can_move:
		move_keys(delta)
	action_keys(delta)

func action_keys(_delta):
	if Input.is_action_just_pressed("escape"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		OS.window_fullscreen = !OS.window_fullscreen
	if Input.is_action_just_pressed("hide_ui"):
		hud.set_visible(!hud.visible)
	if Input.is_action_just_pressed("zoom"):
		zoom_tween.interpolate_property(cam, "translation", cam.translation, Vector3(0, 0, 4), 0.5, Tween.TRANS_QUAD)
		zoom_tween.start()
	if Input.is_action_just_released("zoom"):
		zoom_tween.interpolate_property(cam, "translation", cam.translation, Vector3(0, 0, 0), 0.5, Tween.TRANS_QUAD)
		zoom_tween.start()
		

func move_keys(delta):
	# Direction inputs
	direction = Vector3()
	
	if Input.is_action_pressed("forward"):
		direction.z += -1
	if Input.is_action_pressed("backward"):
		direction.z += 1
	if Input.is_action_pressed("left"):
		direction.x += -1
	if Input.is_action_pressed("right"):
		direction.x += 1
	
	direction = direction.normalized()
	
	# Rotates the direction from the Y axis to move forward
	direction = direction.rotated(Vector3.UP, rotation.y)
	
	# Snaps the character on the ground and changes the gravity vector to climb
	# slopes at the same speed until 45 degrees
	if is_on_floor():
		acceleration = ground_acceleration
		movement.y = 0
		gravity_vec = -get_floor_normal() * 10
		snapped = true
		
	else:
		acceleration = air_acceleration
		if snapped:
			gravity_vec = Vector3()
			snapped = false
		else:
			gravity_vec += Vector3.DOWN * gravity * delta
	
	if Input.is_action_pressed("jump"):
		if is_on_floor() and can_jump:
			snapped = false
			can_jump = false
			gravity_vec = Vector3.UP * jump_height
	else:
		can_jump = true
	
	if is_on_ceiling():
		gravity_vec.y = 0
	
	velocity = velocity.linear_interpolate(direction * current_speed, acceleration * delta)
	
	movement = velocity + gravity_vec
	
	movement = move_and_slide(movement, Vector3.UP)

