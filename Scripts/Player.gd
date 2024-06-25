extends CharacterBody3D

const MAP_SIZE = Vector2(200.0, 200.0)
const DEFAULT_MOVEMENT_SPEED := 3.5
const RUN_MOVEMENT_SPEED := 4.5
const HARVEST_MOVEMENT_SPEED := 1.0
const ACCELERATION := 0.3
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()

var physical_damage := 50.0
var magic_damage := 50.0
var physical_armor := 15.0
var magic_armor := 15.0
var movement_speed := RUN_MOVEMENT_SPEED
var souls := 0
var cooldown_reduction := 0.0
var health_regeneration := 10.0
var energy_regeneration := 20.0
var max_health := 1000.0
var max_energy := 800.0
var life_steal := 0.0

var recall := false

var in_workshop := false
var category_selected := 0
var item_selected : Item

var components := {}
var items := []

var can_move := true

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_hud = preload("res://Scenes/UI/ItemHud.tscn")
var pre_item_workshop_list = preload("res://Scenes/UI/ItemWorkshopList.tscn")
var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")
var pre_item_drop = preload("res://Scenes/ItemDrop.tscn")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

@onready var camera := $Camera
@onready var camera_base_marker := $CameraBaseMarker
#@onready var nav := $NavAgent
@onready var recall_visual := $RecallVisual
@onready var recall_timer := $Recall
@onready var hud := $CanvasLayer/HUD
@onready var scoreboard := $CanvasLayer/HUD/ScoreBoard
@onready var chat := $CanvasLayer/HUD/Chat
@onready var component_list := $CanvasLayer/HUD/Components/Pad/CompList
@onready var item_list = $CanvasLayer/HUD/ActionPanel/ItemBar/Pad/ItemList
@onready var channeling_bar := $CanvasLayer/HUD/ChannelingBar
@onready var mini_map := $CanvasLayer/HUD/MiniMap
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
	obtain_item(preload("res://Ressources/Items/HunterMachette.tres"))
	reset_speed()

func _physics_process(_delta) -> void:
	#cam_movement()
	movement()
	action_keys()
	debug_features()

func _process(_delta):
	update_direction()
	mini_map.update_camera_position(camera.global_position, camera_base_marker.position)
	mini_map.update_player_position(global_position)

func update_map_data(paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, interests_data : PackedVector2Array) -> void:
	mini_map.initialize_minimap(MAP_SIZE, paths_data, bases_data, interests_data)
	initialize_fog_map(bases_data)

func update_direction() -> void:
	player_model.look_at(-target_direction + Vector3(global_position.x, player_model.global_position.y, global_position.z))

const CAM_LIMITS = Rect2(Vector2(-89.0, -89.0), Vector2(89, 95))
var move_camera = false
#func cam_movement() -> void:
	#if get_viewport().get_mouse_position().x/1918.5 > 1 - get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		#camera.global_position.x = min(camera.global_position.x + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.x)
	#if get_viewport().get_mouse_position().x/1918.5 < get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		#camera.global_position.x = max(camera.global_position.x - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.x)
	#if get_viewport().get_mouse_position().y/1078.5 > 1 - get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		#camera.global_position.z = min(camera.global_position.z + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.y)
	#if get_viewport().get_mouse_position().y/1078.5 < get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		#camera.global_position.z = max(camera.global_position.z - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.y)

func move_camera_by_minimap(pos : Vector2) -> void:
	if move_camera:
		camera.global_position.x = clamp(pos.x, CAM_LIMITS.position.x, CAM_LIMITS.size.x)
		camera.global_position.z = clamp(pos.y, CAM_LIMITS.position.y, CAM_LIMITS.size.y)

func set_moving_map(moving : bool) -> void:
	move_camera = moving
	camera.top_level = moving
	camera.position = camera_base_marker.position

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

#const RAY_LENGTH := 100.0
#func _unhandled_input(event) -> void:
	#if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		#var _mouse_pos = get_viewport().get_mouse_position()
		#var _ray_query = PhysicsRayQueryParameters3D.new()
		#_ray_query.from = camera.project_ray_origin(_mouse_pos)
		#_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		#_ray_query.collision_mask = 1
		#var _result = get_world_3d().direct_space_state.intersect_ray(_ray_query)
		#if !_result.is_empty():
			#nav.target_position = _result.get("position")
			#if recall:
				#cancel_recall()

func cancel_recall() -> void:
	recall_timer.stop()
	recall = false
	stop_channeling()
	recall_visual.set_visible(false)

func respawn_base() -> void:
	global_position = get_node("..").get_node("NavMesh/Base/PlayerSpawn/1").global_position
	#nav.target_position = global_position
	camera.global_position = camera_base_marker.global_position

func movement() -> void:
	#var input_dir = Vector3()
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	#if input_dir != Vector2():
		#nav.target_position = global_position
	#elif !nav.is_navigation_finished():
		#var _direction_result = global_position.direction_to(nav.get_next_path_position())
		#input_dir = Vector2(_direction_result.x, _direction_result.z)
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
		set_moving_map(false)
	if Input.is_action_pressed("center_cam"):
		camera.global_position = camera_base_marker.global_position
	
	if Input.is_action_just_pressed("recall"):
		#nav.target_position = global_position
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


var channeling_tween
func start_channeling(duration : float) -> void:
	channeling_bar.set_visible(true)
	if channeling_tween:
		channeling_tween.kill()
	channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	channeling_tween.tween_method(Callable(channeling_bar, "set_value"), 0.0, 100.0, duration)

func stop_channeling() -> void:
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

func obtain_item(item : Item) -> void:
	items.append(item)
	update_items()

func update_items() -> void:
	for i in item_list.get_children():
		i.queue_free()
	for i in items:
		var _new_item_hud = pre_item_hud.instantiate()
		_new_item_hud.item = i
		_new_item_hud.connect("drag_drop_item", Callable(self, "drop_item"))
		item_list.add_child(_new_item_hud)

const DROP_VECTOR_LENGTH = 1.4
func drop_item(item : Item) -> void:
	items.remove_at(items.find(item))
	var _new_item_ground = pre_item_drop.instantiate()
	var _vector_drop = Vector2().direction_to(get_viewport().get_mouse_position() - get_window().size/2.0)
	_new_item_ground.position = Vector3(_vector_drop.x, 0.0, _vector_drop.y) * DROP_VECTOR_LENGTH + global_position
	_new_item_ground.item = item
	get_node("..").add_child(_new_item_ground)
	update_items()

func entering_workshop() -> void:
	in_workshop = true

func exit_workshop() -> void:
	in_workshop = false

func select_item(item : Item) -> void:
	item_selected = item
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
		workshop_item_craft_button.disabled = !is_item_craftable(item, components) or items.has(item)
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

var fog_map : Image
var density_tex : ImageTexture3D
const FOG_RESOLUTION = 9
const FOG_TEXTURE_SIZE = Vector2i(int(MAP_SIZE.x) * FOG_RESOLUTION, int(MAP_SIZE.y) * FOG_RESOLUTION)
const FOG_PLAYER_SIZE = Vector2i(36, 36) * FOG_RESOLUTION
const FOG_BASE_SIZE = Vector2i(24, 24) * FOG_RESOLUTION
func initialize_fog_map(bases_data : PackedVector2Array) -> void:
	fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	fog_map.fill(Color(1.0, 1.0, 1.0))
	density_tex = ImageTexture3D.new()
	density_tex.create(Image.FORMAT_RGBA8, FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, 1, false, [fog_map])
	mini_map.initialize_fog(bases_data, FOG_BASE_SIZE, FOG_PLAYER_SIZE, FOG_TEXTURE_SIZE)
	update_map_fog()

func update_map_fog() -> void:
	var _fog_position = world_to_fog_position(Vector2(global_position.x, global_position.z))
	var _player_img = pre_circle_image.duplicate()
	_player_img.resize(FOG_PLAYER_SIZE.x, FOG_PLAYER_SIZE.y, Image.INTERPOLATE_NEAREST)
	fog_map.blend_rect(pre_circle_image, pre_circle_image.get_used_rect(), _fog_position - pre_circle_image.get_size()/2)
	mini_map.update_fog(fog_map, FOG_PLAYER_SIZE, global_position)
	density_tex.update([fog_map])
	get_node("..").get_node("FogOfWar").material.set("density_texture", density_tex)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_close_workshop_pressed() -> void:
	workshop.set_visible(false)

func _on_nav_agent_path_changed() -> void:
	pass
	#update_movement_line()

func _on_update_movement_line_timeout() -> void:
	pass
	#if nav.target_position == Vector3(0.0, 0.0, 0.0):
		#nav.target_position = global_position
	#nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)
	update_map_fog()

func _on_recall_timeout() -> void:
	respawn_base()
	cancel_recall()

func _on_craft_item_pressed():
	if in_workshop:
		for c in range(item_selected.craft_recipe.size()):
			if item_selected.craft_recipe.values()[c] == components.get(item_selected.craft_recipe.keys()[c]):
				components.erase(item_selected.craft_recipe.keys()[c])
			else:
				var _new_quantity = components.get(item_selected.craft_recipe.keys()[c]) - item_selected.craft_recipe.values()[c]
				
				var _new_components = {item_selected.craft_recipe.keys()[c]:_new_quantity}
				components.merge(_new_components, true)
		update_components()
		update_workshop_inspection_tab(item_selected)
	
