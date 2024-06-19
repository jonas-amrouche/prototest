extends CharacterBody3D

const DEFAULT_MOVEMENT_SPEED := 4.0
const RUN_MOVEMENT_SPEED := 6.0
const HARVEST_MOVEMENT_SPEED := 0.0
const ACCELERATION := 0.2
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75

var movement_speed := RUN_MOVEMENT_SPEED

var interactible : Object
var in_interaction_with : Object

var in_workshop := false

var components := {}
var items := []

var can_move := true

var pre_component_ui = preload("res://Scenes/ComponentUI.tscn")

@onready var camera := $Camera
@onready var camera_marker := $CameraMarker
@onready var camera_base_marker := $CameraBaseMarker
@onready var indic_inter := $CanvasLayer/HUD/InteractionIndicator
@onready var hud = $CanvasLayer/HUD
@onready var scoreboard = $CanvasLayer/HUD/ScoreBoard
@onready var component_list = $CanvasLayer/HUD/Inventory/CompList
@onready var channeling_bar = $CanvasLayer/HUD/ChannelingBar
@onready var mini_player = $CanvasLayer/HUD/MiniMap/MiniPlayer
@onready var mini_camera = $CanvasLayer/HUD/MiniMap/MiniCamera
@onready var workshop = $CanvasLayer/HUD/Workshop

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)

func _physics_process(_delta) -> void:
	cam_movement()
	smooth_camera()
	move_keys()
	action_keys()
	debug_features()

func _process(_delta):
	update_player_position()
	update_camera_position()

func update_player_position() -> void:
	mini_player.position = ((Vector2(global_position.x, global_position.z) + Vector2(45.5, 45.5)*5.0)*2.6)/5.0

func update_camera_position() -> void:
	mini_camera.position = ((Vector2(camera.global_position.x, camera.global_position.z) + Vector2(38.25, 40.0)*5.0)*2.6)/5.0

func cam_movement() -> void:
	#print(get_viewport().get_mouse_position(), get_viewport().size)
	if get_viewport().get_mouse_position().x/1918.5 > 1 - get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera_marker.global_position.x += CAMERA_MOOVE_SPEED
	if get_viewport().get_mouse_position().x/1918.5 < get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera_marker.global_position.x -= CAMERA_MOOVE_SPEED
	if get_viewport().get_mouse_position().y/1078.5 > 1 - get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera_marker.global_position.z += CAMERA_MOOVE_SPEED
	if get_viewport().get_mouse_position().y/1078.5 < get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera_marker.global_position.z -= CAMERA_MOOVE_SPEED

func smooth_camera() -> void:
	camera.global_position.x = lerp(camera.global_position.x, camera_marker.global_position.x, CAMERA_LERP_SPEED)
	camera.global_position.z = lerp(camera.global_position.z, camera_marker.global_position.z, CAMERA_LERP_SPEED)

func debug_features() -> void:
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.WINDOW_MODE_WINDOWED: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if Input.is_action_just_pressed("hide_ui"):
		hud.set_visible(!hud.visible)
	if Input.is_action_just_pressed("free_mouse"):
		match DisplayServer.mouse_get_mode():
			DisplayServer.MOUSE_MODE_CONFINED: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
			DisplayServer.MOUSE_MODE_VISIBLE: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)

func move_keys() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and can_move:
		velocity.x = lerp(velocity.x, direction.x * movement_speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * movement_speed, ACCELERATION)
	else:
		velocity.x = lerp(velocity.x, 0.0, ACCELERATION)
		velocity.z = lerp(velocity.z, 0.0, ACCELERATION)
	
	move_and_slide()

func reset_speed():
	if items.is_empty():
		movement_speed = RUN_MOVEMENT_SPEED
	else:
		movement_speed = DEFAULT_MOVEMENT_SPEED

func action_keys():
	if Input.is_action_just_released("left_click"):
		move_cam = false
	if Input.is_action_pressed("center_cam"):
		#camera.global_position = camera_base_marker.global_position
		camera_marker.global_position = camera_base_marker.global_position
	
	if Input.is_action_just_pressed("interact"):
		if interactible:
			interaction_start(interactible.id)
	if Input.is_action_just_released("interact"):
		if in_interaction_with == interactible and interactible:
			interaction_cancel(interactible.id)
	if Input.is_action_just_pressed("show_scoreboard"):
		scoreboard.set_visible(!scoreboard.visible)
	if Input.is_action_just_released("show_scoreboard"):
		scoreboard.set_visible(!scoreboard.visible)
	if Input.is_action_just_pressed("workshop"):
		workshop.set_visible(!workshop.visible)

var channeling_tween
func interaction_start(interaction : String) -> void:
	match interaction:
		"plant":
			if interactible.grown:
				interactible.start_harvesting(self)
				in_interaction_with = interactible
				movement_speed = HARVEST_MOVEMENT_SPEED
				channeling_bar.set_visible(true)
				if channeling_tween:
					channeling_tween.kill()
				channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
				channeling_tween.tween_method(Callable(channeling_bar, "set_value"), 0.0, 100.0, interactible.harvest_time)

func interaction_cancel(interaction : String) -> void:
	match interaction:
		"plant":
			interactible.stop_harvesting()
			in_interaction_with = null
			reset_speed()
			channeling_bar.set_visible(false)

func interaction_success(interaction : String, args1 = null, args2 = null) -> void:
	match interaction:
		"plant":
			obtain_component(args1, args2)
			in_interaction_with = null
			reset_speed()
			channeling_bar.set_visible(false)

func obtain_component(comps : String, quantity : int) -> void:
	var _old_quantity = components.get(comps)
	var _new_quantity = quantity
	
	if _old_quantity:
		_new_quantity += _old_quantity
	
	var _new_components = {comps:_new_quantity}
	components.merge(_new_components, true)
	update_components()

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(components.size()):
		var _new_component_ui = pre_component_ui.instantiate()
		_new_component_ui.get_node("Quantity").text = str(components.values()[i])
		component_list.add_child(_new_component_ui)

func entering_workshop() -> void:
	in_workshop = true

func exit_workshop() -> void:
	in_workshop = false

func _on_interact_area_entered(area):
	interactible = area.get_node("..")
	if Input.is_action_pressed("interact"):
		interaction_start(interactible.id)
	indic_inter.set_visible(true)

func _on_interact_area_exited(area):
	if in_interaction_with == interactible:
		interaction_cancel(in_interaction_with.id)
	
	if interactible == area.get_node(".."):
		interactible = null
		indic_inter.set_visible(false)

var move_cam = false
var cursor_pos = Vector2()
func _on_area_input_event(viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			move_cam = true
		else:
			move_cam = false
	if event is InputEventMouseMotion:
		cursor_pos = ((viewport.get_mouse_position() - Vector2(28.0, 28.0)) / 2.62 - Vector2(50.0, 50.0))*5.0
	if move_cam:
		camera_marker.global_position.x = cursor_pos.x
		camera_marker.global_position.z = cursor_pos.y
		#camera.global_position.x = cursor_pos.x
		#camera.global_position.z = cursor_pos.y

func _on_close_workshop_pressed():
	workshop.set_visible(false)
