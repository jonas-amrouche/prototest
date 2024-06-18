extends CharacterBody3D

const SPEED := 4.0
const ACCELERATION := 0.2
const CAMERA_LERP_SPEED := 0.5

var interactible : Object
var in_interaction_with : Object

var components := {}
var items := []

var can_move := true

var pre_component_ui = preload("res://Scenes/ComponentUI.tscn")

@onready var camera := $Camera
@onready var camera_marker := $CameraMarker
@onready var indic_inter := $CanvasLayer/HUD/InteractionIndicator
@onready var hud = $CanvasLayer/HUD
@onready var scoreboard = $CanvasLayer/HUD/ScoreBoard
@onready var component_list = $CanvasLayer/HUD/Inventory/CompList

func _physics_process(delta) -> void:
	smooth_camera()
	move_keys()
	action_keys()
	debug_features()

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

func move_keys() -> void:
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and can_move:
		velocity.x = lerp(velocity.x, direction.x * SPEED, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * SPEED, ACCELERATION)
	else:
		velocity.x = lerp(velocity.x, 0.0, ACCELERATION)
		velocity.z = lerp(velocity.z, 0.0, ACCELERATION)
	
	move_and_slide()

func action_keys():
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

func interaction_start(interaction : String) -> void:
	match interaction:
		"plant":
			interactible.start_harvesting(self)
			in_interaction_with = interactible
			can_move = false

func interaction_cancel(interaction : String) -> void:
	match interaction:
		"plant":
			interactible.stop_harvesting()
			in_interaction_with = null
			can_move = true

func interaction_success(interaction : String, args1 = null, args2 = null) -> void:
	match interaction:
		"plant":
			obtain_component(args1, args2)
			in_interaction_with = null
			can_move = true

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
