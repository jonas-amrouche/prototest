extends CharacterBody3D

const DEFAULT_MOVEMENT_SPEED := 4.0
const RUN_MOVEMENT_SPEED := 6.0
const HARVEST_MOVEMENT_SPEED := 0.0
const ACCELERATION := 0.2
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()

var movement_speed := DEFAULT_MOVEMENT_SPEED

var interactible : Object
var in_interaction_with : Object

var in_workshop := false
var category_selected := 0

var components := {}
var items := []

var can_move := true

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_workshop_list = preload("res://Scenes/UI/ItemWorkshopList.tscn")

var items_list = [preload("res://Ressources/Items/HunterMachette.tres")]

@onready var camera := $Camera
@onready var camera_marker := $CameraMarker
@onready var camera_base_marker := $CameraBaseMarker
@onready var nav := $NavAgent
@onready var indic_inter := $CanvasLayer/HUD/InteractionIndicator
@onready var hud = $CanvasLayer/HUD
@onready var scoreboard = $CanvasLayer/HUD/ScoreBoard
@onready var component_list = $CanvasLayer/HUD/Components/Pad/CompList
@onready var channeling_bar = $CanvasLayer/HUD/ChannelingBar
@onready var mini_map = $CanvasLayer/HUD/MiniMap
@onready var mini_player = $CanvasLayer/HUD/MiniMap/MiniPlayer
@onready var mini_camera = $CanvasLayer/HUD/MiniMap/MiniCamera
@onready var workshop = $CanvasLayer/HUD/Workshop
@onready var workshop_item_list = $CanvasLayer/HUD/Workshop/ItemBoard/ItemListContainer/Pad/ItemList
@onready var player_model = $PlayerModel
@onready var anims = $Anims

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)

func _physics_process(_delta) -> void:
	cam_movement()
	smooth_camera()
	movement()
	action_keys()
	debug_features()

func _process(_delta):
	update_direction()
	update_player_position()
	update_camera_position()

func update_direction() -> void:
	player_model.look_at(-target_direction + Vector3(global_position.x, player_model.global_position.y, global_position.z))

func update_player_position() -> void:
	mini_player.position = (Vector2(global_position.x, global_position.z) + Vector2(100.0, 100.0))*(mini_map.size.x/100.0)/2.0 - mini_player.size/2.0

func update_camera_position() -> void:
	mini_camera.position = (Vector2(camera.global_position.x, camera.global_position.z - 3.0) + Vector2(100.0, 100.0))*(mini_map.size.x/100.0)/2.0 - mini_camera.size/2.0

func cam_movement() -> void:
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

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_length = 100.0
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * _ray_length
		var _result = get_world_3d().direct_space_state.intersect_ray(_ray_query)
		if !_result.is_empty():
			nav.target_position = _result.get("position")

func movement() -> void:
	var input_dir = Vector3()
	if !nav.is_navigation_finished():
		input_dir =  global_position.direction_to(nav.get_next_path_position())
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.z)).normalized()
	
	if direction and can_move:
		anims.play("walk", 1.0)
		velocity.x = lerp(velocity.x, direction.x * movement_speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * movement_speed, ACCELERATION)
		face_direction(direction)
	else:
		anims.play("idle", 1.0)
		velocity.x = lerp(velocity.x, 0.0, ACCELERATION)
		velocity.z = lerp(velocity.z, 0.0, ACCELERATION)
	
	move_and_slide()

func face_direction(direction : Vector3) -> void:
	target_direction = lerp(target_direction, direction, ROTATION_LERP_SPEED)

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
		update_workshop_item_list(category_selected)
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
		var _new_component_ui = pre_component_hud.instantiate()
		_new_component_ui.get_node("Quantity").text = str(components.values()[i])
		component_list.add_child(_new_component_ui)

func entering_workshop() -> void:
	in_workshop = true

func exit_workshop() -> void:
	in_workshop = false

func update_workshop_item_list(category : int) -> void:
	for i in workshop_item_list.get_children():
		i.queue_free()
	match category:
		0:
			for i in range(items_list.size()):
				var _new_item = pre_item_workshop_list.instantiate()
				_new_item.item = items_list[i]
				workshop_item_list.add_child(_new_item)

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
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				move_cam = true
			else:
				move_cam = false
		elif event.button_index == 2:
			if event.pressed:
				cursor_pos = ((viewport.get_mouse_position() - mini_map.position) / (mini_map.size.x/100.0)*2.0 - Vector2(100.0, 100.0))
				nav.target_position = Vector3(cursor_pos.x, 0, cursor_pos.y)
	if event is InputEventMouseMotion:
		cursor_pos = ((viewport.get_mouse_position() - mini_map.position) / (mini_map.size.x/100.0)*2.0 - Vector2(100.0, 100.0))
	if move_cam:
		camera_marker.global_position.x = cursor_pos.x
		camera_marker.global_position.z = cursor_pos.y

func _on_close_workshop_pressed():
	workshop.set_visible(false)
