extends CharacterBody3D

const MAP_SIZE = Vector2(200.0, 200.0)
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
var pre_base_texture = preload("res://Assets/2D/UI/altar_icon.png")
var pre_plant_texture = preload("res://Assets/2D/UI/plant_icon.png")
var pre_base_area_texture = preload("res://Assets/2D/UI/base_area_path.png")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

@onready var camera := $Camera
@onready var camera_marker := $CameraMarker
@onready var camera_base_marker := $CameraBaseMarker
@onready var nav := $NavAgent
@onready var indic_inter := $CanvasLayer/HUD/InteractionIndicator
@onready var hud := $CanvasLayer/HUD
@onready var scoreboard := $CanvasLayer/HUD/ScoreBoard
@onready var chat := $CanvasLayer/HUD/Chat
@onready var component_list := $CanvasLayer/HUD/Components/Pad/CompList
@onready var channeling_bar := $CanvasLayer/HUD/ChannelingBar
@onready var mini_map := $CanvasLayer/HUD/MiniMap
@onready var mini_player := $CanvasLayer/HUD/MiniMap/MiniPlayer
@onready var mini_camera := $CanvasLayer/HUD/MiniMap/MiniCamera
@onready var mini_content := $CanvasLayer/HUD/MiniMap/Content
@onready var mini_movement_lines := $CanvasLayer/HUD/MiniMap/MovementLines
@onready var workshop := $CanvasLayer/HUD/Workshop
@onready var workshop_item_list := $CanvasLayer/HUD/Workshop/ItemBoard/ItemListContainer/Pad/ItemList
@onready var player_model := $PlayerModel
@onready var anims := $Anims

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
	mini_player.position = (Vector2(global_position.x, global_position.z) + MAP_SIZE/2.0)*(mini_map.size.x/(MAP_SIZE.x/2.0))/2.0 - mini_player.size/2.0

func update_camera_position() -> void:
	mini_camera.position = (Vector2(camera.global_position.x, camera.global_position.z - 3.0) + MAP_SIZE/2.0)*(mini_map.size.x/(MAP_SIZE.x/2.0))/2.0 - mini_camera.size/2.0

const MAP_PATH_WIDTH := 9.0
const MAP_MID_WIDTH := 11.0
const MAP_PATH_COLOR := Color(0.275, 0.339, 0.316)
const MAP_BASE_ICON_SIZE := Vector2(30.0, 30.0)
const MAP_BASE_AREA_SIZE := Vector2(50.0, 50.0)
const MAP_PLANT_ICON_SIZE := Vector2(15.0, 15.0)
func update_mini_map_points(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, plants_data : PackedVector2Array) -> void:
	# Format Paths
	var _new_paths_data : Array[PackedVector2Array]
	for path in paths_data:
		var _temp_path : PackedVector2Array
		for point in path:
			_temp_path.append(world_to_minimap_position(point))
		_new_paths_data.append(_temp_path)
	# Draw Paths
	for path in _new_paths_data:
		draw_line(path, MAP_PATH_WIDTH, MAP_PATH_COLOR)
	# Draw Midlane
	draw_line([world_to_minimap_position(bases_data[0]), world_to_minimap_position(bases_data[1])], MAP_MID_WIDTH, MAP_PATH_COLOR)
	# Draw Camps Icons
	for base in bases_data:
		draw_icon(base, MAP_BASE_AREA_SIZE, pre_base_area_texture, MAP_PATH_COLOR)
		draw_icon(base, MAP_BASE_ICON_SIZE, pre_base_texture)
	# Draw Plant Icons
	for plant in plants_data:
		draw_icon(plant, MAP_PLANT_ICON_SIZE, pre_plant_texture)

func draw_line(points : PackedVector2Array, width : float, tint : Color, parent : Object = mini_content) -> void:
	var _new_line = Line2D.new()
	_new_line.points = points
	_new_line.width = width
	_new_line.default_color = tint
	_new_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_new_line.antialiased = true
	parent.add_child(_new_line)

func clear_movement_lines() -> void:
	for l in mini_movement_lines.get_children():
		l.queue_free()

func draw_icon(pos : Vector2, size : Vector2, icon : Texture2D, tint : Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	var _new_base_icon = TextureRect.new()
	_new_base_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_new_base_icon.size = size
	_new_base_icon.texture = icon
	_new_base_icon.position = world_to_minimap_position(pos) - _new_base_icon.size/2.0
	_new_base_icon.self_modulate = tint
	mini_content.add_child(_new_base_icon)

func world_to_minimap_position(pos : Vector2) -> Vector2:
	return (pos + MAP_SIZE/2.0)/MAP_SIZE*mini_content.size

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

const RAY_LENGTH := 100.0
func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
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
	if Input.is_action_just_pressed("chat"):
		chat.set_visible(!chat.visible)
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
				channeling_tween.tween_method(Callable(channeling_bar, "set_value"), 0.0, 100.0, interactible.plant.harvest_time)

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
			for i in range(args1.size()):
				obtain_component(args1[i], args2[i])
			in_interaction_with = null
			reset_speed()
			channeling_bar.set_visible(false)

func obtain_component(comps : Component, quantity : int) -> void:
	var _new_quantity = quantity
	if components.has(comps.id):
		var _old_quantity = components.get(comps.id)[1]
		
		if _old_quantity:
			_new_quantity += _old_quantity
	
	var _new_components = {comps.id:[comps, _new_quantity]}
	components.merge(_new_components, true)
	update_components()

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(components.size()):
		var _new_component_ui = pre_component_hud.instantiate()
		_new_component_ui.get_node("MarginQuantity/Quantity").text = str(components.values()[i][1])
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
			for i in range(all_item_base.base.size()):
				var _new_item = pre_item_workshop_list.instantiate()
				_new_item.item = all_item_base.base[i]
				workshop_item_list.add_child(_new_item)

func _on_interact_area_entered(area):
	interactible = area.get_node("..")
	if Input.is_action_pressed("interact"):
		interaction_start(interactible.id)
	indic_inter.set_visible(true)

func _on_interact_area_exited(area):
	if in_interaction_with and in_interaction_with == interactible :
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
				cursor_pos = ((viewport.get_mouse_position() - mini_map.position) / (mini_map.size.x/(MAP_SIZE.x/2.0))*2.0 - MAP_SIZE/2.0)
				nav.target_position = Vector3(cursor_pos.x, 0, cursor_pos.y)
	if event is InputEventMouseMotion:
		cursor_pos = ((viewport.get_mouse_position() - mini_map.position) / (mini_map.size.x/(MAP_SIZE.x/2.0))*2.0 - MAP_SIZE/2.0)
	if move_cam:
		camera_marker.global_position.x = cursor_pos.x
		camera_marker.global_position.z = cursor_pos.y

const MOVEMENT_LINE_WIDTH := 1.0
func update_movement_line() -> void:
	clear_movement_lines()
	var _2d_map_navigation_path : PackedVector2Array
	for p in nav.get_current_navigation_path():
		_2d_map_navigation_path.append(world_to_minimap_position(Vector2(p.x, p.z)))
	draw_line(_2d_map_navigation_path, MOVEMENT_LINE_WIDTH, Color(1.0, 1.0, 1.0, 1.0), mini_movement_lines)

func _on_close_workshop_pressed():
	workshop.set_visible(false)

func _on_nav_agent_path_changed():
	update_movement_line()

func _on_update_movement_line_timeout():
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)
