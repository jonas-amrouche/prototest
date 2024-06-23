extends CharacterBody3D

const MAP_SIZE = Vector2(200.0, 200.0)
const DEFAULT_MOVEMENT_SPEED := 2.5
const RUN_MOVEMENT_SPEED := 4.0
const HARVEST_MOVEMENT_SPEED := 1.0
const ACCELERATION := 0.3
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()

var movement_speed := RUN_MOVEMENT_SPEED

var interactible : Object
var in_interaction_with : Object

var recall := false

var in_workshop := false
var category_selected := 0

var components := {}
var items := []

var attack_mode := false
var can_move := true

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_workshop_list = preload("res://Scenes/UI/ItemWorkshopList.tscn")
var pre_base_texture = preload("res://Assets/2D/UI/altar_icon.png")
var pre_plant_texture = preload("res://Assets/2D/UI/plant_icon.png")
var pre_base_area_texture = preload("res://Assets/2D/Ui/base_area_path.png")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

@onready var camera := $Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var nav := $NavAgent
@onready var recall_visual := $RecallVisual
@onready var recall_timer := $Recall
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
@onready var map_mask := $CanvasLayer/HUD/MiniMap/MapMask
@onready var workshop := $CanvasLayer/HUD/Workshop
@onready var workshop_item_list := $CanvasLayer/HUD/Workshop/ItemBoard/ItemListContainer/Pad/ItemList
@onready var workshop_item_inspection_icon := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemView
@onready var workshop_item_inspection_name := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemName
@onready var workshop_item_inspection_desc := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemDesc
@onready var workshop_item_inspection_comps := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ComponentsNeeded
@onready var workshop_item_craft_button := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/CraftItem
@onready var player_model := $PlayerModel
@onready var anims := $Anims

#1 script pour le fog
#1 script pour la map
#1 script pour le workshop
#1 script pour l'hud

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)

func _physics_process(_delta) -> void:
	cam_movement()
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
func update_mini_map_data(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, plants_data : PackedVector2Array) -> void:
	# Format Paths
	var _new_paths_data = Array(PackedVector2Array())
	for path in paths_data:
		var _temp_path = PackedVector2Array()
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
	initialize_fog_map(bases_data)
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

const CAM_LIMITS = Rect2(Vector2(-85.0, -89.0), Vector2(85, 95))
func cam_movement() -> void:
	if get_viewport().get_mouse_position().x/1918.5 > 1 - get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.x = min(camera.global_position.x + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.x)
	if get_viewport().get_mouse_position().x/1918.5 < get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.x = max(camera.global_position.x - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.x)
	if get_viewport().get_mouse_position().y/1078.5 > 1 - get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.z = min(camera.global_position.z + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.y)
	if get_viewport().get_mouse_position().y/1078.5 < get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.z = max(camera.global_position.z - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.y)

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
func _unhandled_input(event) -> void:
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		_ray_query.collision_mask = 1
		var _result = get_world_3d().direct_space_state.intersect_ray(_ray_query)
		if !_result.is_empty():
			nav.target_position = _result.get("position")
			if recall:
				cancel_recall()

func cancel_recall() -> void:
	recall_timer.stop()
	recall = false
	stop_channeling()
	recall_visual.set_visible(false)

func respawn_base() -> void:
	global_position = get_node("..").get_node("NavMesh/Base/PlayerSpawn/1").global_position
	nav.target_position = global_position
	camera.global_position = camera_base_marker.global_position

func change_move_mode(mode : int) -> void:
	update_movement_line()
	attack_mode = mode

func movement() -> void:
	#var input_dir = Vector3()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_dir != Vector2():
		change_move_mode(1)
		nav.target_position = global_position
	elif !nav.is_navigation_finished():
		change_move_mode(0)
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
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

func reset_speed() -> void:
	if items.is_empty():
		movement_speed = RUN_MOVEMENT_SPEED
	else:
		movement_speed = DEFAULT_MOVEMENT_SPEED

func action_keys():
	if Input.is_action_just_released("left_click"):
		move_cam = false
	if Input.is_action_pressed("center_cam"):
		camera.global_position = camera_base_marker.global_position
	
	if Input.is_action_just_pressed("interact"):
		if interactible:
			interaction_start(interactible.id)
	if Input.is_action_just_released("interact"):
		if in_interaction_with == interactible and interactible:
			interaction_cancel(interactible.id)
	if Input.is_action_just_pressed("recall"):
		nav.target_position = global_position
		recall = true
		recall_timer.start()
		start_channeling(recall_timer.wait_time)
		recall_visual.set_visible(true)
	if Input.is_action_just_pressed("show_scoreboard"):
		scoreboard.set_visible(!scoreboard.visible)
	if Input.is_action_just_released("show_scoreboard"):
		scoreboard.set_visible(!scoreboard.visible)
	if Input.is_action_just_pressed("chat"):
		chat.set_visible(!chat.visible)
	if Input.is_action_just_pressed("workshop"):
		update_workshop_item_list(category_selected)
		workshop.set_visible(!workshop.visible)

func interaction_start(interaction : String) -> void:
	match interaction:
		"plant":
			if interactible.grown:
				interactible.start_harvesting(self)
				in_interaction_with = interactible
				movement_speed = HARVEST_MOVEMENT_SPEED
				start_channeling(interactible.plant.harvest_time)

var channeling_tween
func start_channeling(duration : float) -> void:
	channeling_bar.set_visible(true)
	if channeling_tween:
		channeling_tween.kill()
	channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	channeling_tween.tween_method(Callable(channeling_bar, "set_value"), 0.0, 100.0, duration)

func stop_channeling() -> void:
	channeling_bar.set_visible(false)

func interaction_cancel(interaction : String) -> void:
	match interaction:
		"plant":
			interactible.stop_harvesting()
			in_interaction_with = null
			reset_speed()
			stop_channeling()

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
	if components.has(comps):
		var _old_quantity = components.get(comps)
		
		if _old_quantity:
			_new_quantity += _old_quantity
	
	var _new_components = {comps:_new_quantity}
	components.merge(_new_components, true)
	update_components()

func update_components() -> void:
	for i in component_list.get_children():
		i.queue_free()
	for i in range(components.size()):
		var _new_component_hud = pre_component_hud.instantiate()
		_new_component_hud.component = components.keys()[i]
		_new_component_hud.quantity = components.values()[i]
		component_list.add_child(_new_component_hud)

func entering_workshop() -> void:
	in_workshop = true

func exit_workshop() -> void:
	in_workshop = false

func select_item(item : Item) -> void:
	update_workshop_inspection_tab(item)

func update_workshop_item_list(category : int) -> void:
	for i in workshop_item_list.get_children():
		i.queue_free()
	match category:
		0:
			for i in range(all_item_base.base.size()):
				var _new_item = pre_item_workshop_list.instantiate()
				_new_item.item = all_item_base.base[i]
				workshop_item_list.add_child(_new_item)
				_new_item.select_item.connect(Callable(self, "select_item"))

func update_workshop_inspection_tab(item : Item) -> void:
	for i in workshop_item_inspection_comps.get_children():
		i.queue_free()
	if item:
		workshop_item_inspection_icon.texture = item.icon
		workshop_item_inspection_name.text = item.name
		workshop_item_inspection_desc.text = item.description
		workshop_item_craft_button.disabled = !is_item_craftable(item, components)
		for c in range(item.craft_recipe.size()):
			var _new_comps_needed = pre_component_hud.instantiate()
			_new_comps_needed.component = item.craft_recipe.keys()[c]
			_new_comps_needed.quantity = item.craft_recipe.values()[c]
			workshop_item_inspection_comps.add_child(_new_comps_needed)
	else:
		workshop_item_inspection_icon.texture = null
		workshop_item_inspection_name.text = ""
		workshop_item_inspection_desc.text = ""
		workshop_item_craft_button.disabled = true

func is_item_craftable(item : Item, comps : Dictionary) -> bool:
	var _component_had = 0
	for r in range(item.craft_recipe.size()):
		for c in range(comps.size()):
			if item.craft_recipe.keys()[r] == comps.keys()[c]:
				if item.craft_recipe.values()[r] <= comps.values()[c]:
					_component_had += 1
	if _component_had == item.craft_recipe.size():
		return true
	return false
	

func _on_interact_area_entered(area) -> void:
	interactible = area.get_node("..")
	if Input.is_action_pressed("interact"):
		interaction_start(interactible.id)
	indic_inter.set_visible(true)

func _on_interact_area_exited(area) -> void:
	if in_interaction_with and in_interaction_with == interactible :
		interaction_cancel(in_interaction_with.id)
	
	if interactible == area.get_node(".."):
		interactible = null
		indic_inter.set_visible(false)

var move_cam = false
var cursor_pos = Vector2()
func _on_area_input_event(viewport, event, _shape_idx) -> void:
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
		camera.global_position.x = clamp(cursor_pos.x, CAM_LIMITS.position.x, CAM_LIMITS.size.x)
		camera.global_position.z = clamp(cursor_pos.y, CAM_LIMITS.position.y, CAM_LIMITS.size.y)

const MOVEMENT_LINE_WIDTH := 1.0
func update_movement_line() -> void:
	clear_movement_lines()
	var _2d_map_navigation_path = PackedVector2Array()
	for p in nav.get_current_navigation_path():
		_2d_map_navigation_path.append(world_to_minimap_position(Vector2(p.x, p.z)))
	draw_line(_2d_map_navigation_path, MOVEMENT_LINE_WIDTH, Color(1.0, 1.0, 1.0, 1.0), mini_movement_lines)

var fog_map : Image
var density_tex : ImageTexture3D
var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")
const FOG_RESOLUTION = 9
const FOG_TEXTURE_SIZE = Vector2i(int(MAP_SIZE.x) * FOG_RESOLUTION, int(MAP_SIZE.y) * FOG_RESOLUTION)
const FOG_PLAYER_SIZE = Vector2i(36, 36) * FOG_RESOLUTION
const FOG_BASE_SIZE = Vector2i(24, 24) * FOG_RESOLUTION
func initialize_fog_map(bases_data : PackedVector2Array) -> void:
	fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	fog_map.fill(Color(1.0, 1.0, 1.0))
	density_tex = ImageTexture3D.new()
	density_tex.create(Image.FORMAT_RGBA8, FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, 1, false, [fog_map])
	initialize_minimap_fog(bases_data)
	update_map_fog()

func update_map_fog() -> void:
	var _fog_position = world_to_fog_position(Vector2(global_position.x, global_position.z))
	var _player_img = pre_circle_image.duplicate()
	_player_img.resize(FOG_PLAYER_SIZE.x, FOG_PLAYER_SIZE.y, Image.INTERPOLATE_NEAREST)
	fog_map.blend_rect(pre_circle_image, pre_circle_image.get_used_rect(), _fog_position - pre_circle_image.get_size()/2)
	update_minimap_fog()
	density_tex.update([fog_map])
	get_node("..").get_node("FogOfWar").material.set("density_texture", density_tex)

func initialize_minimap_fog(bases_data : PackedVector2Array) -> void:
	map_mask.material.set_shader_parameter("base_fog_size", float(FOG_BASE_SIZE.x)/2.0/float(FOG_TEXTURE_SIZE.x))
	map_mask.material.set_shader_parameter("player_fog_size", float(FOG_PLAYER_SIZE.x)/4.5/float(FOG_TEXTURE_SIZE.x))
	map_mask.material.set_shader_parameter("base1_pos", (bases_data[0]+MAP_SIZE/2.0)/MAP_SIZE)
	map_mask.material.set_shader_parameter("base2_pos", (bases_data[1]+MAP_SIZE/2.0)/MAP_SIZE)

func update_minimap_fog() -> void:
	var _new_fog_map = fog_map.duplicate()
	var _player_img = pre_circle_image.duplicate()
	_player_img.resize(FOG_PLAYER_SIZE.x, FOG_PLAYER_SIZE.y, Image.INTERPOLATE_NEAREST)
	_new_fog_map.blend_rect(_player_img, _player_img.get_used_rect(), world_to_fog_position(Vector2(global_position.x, global_position.z)) - _player_img.get_size()/2)
	map_mask.texture = ImageTexture.create_from_image(fog_map)
	map_mask.material.set_shader_parameter("player_pos", (Vector2(global_position.x, global_position.z)+MAP_SIZE/2.0)/MAP_SIZE)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_close_workshop_pressed() -> void:
	workshop.set_visible(false)

func _on_nav_agent_path_changed() -> void:
	update_movement_line()

func _on_update_movement_line_timeout() -> void:
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)
	update_map_fog()

func _on_recall_timeout() -> void:
	respawn_base()
	cancel_recall()

func _on_maintain_harvest_timeout():
	if in_interaction_with and in_interaction_with == interactible :
		interaction_cancel(in_interaction_with.id)
