extends CharacterBody3D

const MAP_SIZE = Vector2(200.0, 200.0)
const DEFAULT_MOVEMENT_SPEED := 3.0
const HARVEST_MOVEMENT_SPEED := 1.0
const ACCELERATION := 0.3
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()


const BASE_PHYSICAL_DAMAGE := 50
const BASE_MAGIC_DAMAGE := 50
const BASE_PHYSICAL_ARMOR := 15
const BASE_MAGIC_ARMOR := 15
const BASE_HEALTH_REGENERATION := 2.0
const BASE_STRENGTH_REGENERATION := 3.0
const BASE_MAX_HEALTH := 450
const BASE_MAX_STRENGTH := 80

var area_health_regeneration := 0.0

var physical_damage := BASE_PHYSICAL_DAMAGE
var magic_damage := BASE_MAGIC_DAMAGE
var physical_armor := BASE_PHYSICAL_ARMOR
var magic_armor := BASE_MAGIC_ARMOR
var movement_speed := DEFAULT_MOVEMENT_SPEED
var souls := 0
var cooldown_reduction := 0.0
var health_regeneration := BASE_HEALTH_REGENERATION
var strength_regeneration := BASE_STRENGTH_REGENERATION
var max_health := BASE_MAX_HEALTH
var max_strength := BASE_MAX_STRENGTH
var life_steal := 0.0
var health := max_health
var strength := max_strength

var recall := false

const SPAWN_REGEN = 100.0
var in_workshop := false
var category_selected := 0
var item_workshop_selected : Item

var components := {}
var items := []
var abilities := [null, null, null, null, null, null, null, null, null, null]
#var item_selected : int

var can_move := true

var pre_component_hud = preload("res://Scenes/Ui/ComponentHud.tscn")
var pre_item_hud = preload("res://Scenes/UI/ItemHud.tscn")
var pre_ability_hud = preload("res://Scenes/UI/AbilityHud.tscn")
var pre_item_workshop_list = preload("res://Scenes/UI/ItemWorkshopList.tscn")
var pre_stat_hud = preload("res://Scenes/UI/StatHud.tscn")
var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")
var pre_item_drop = preload("res://Scenes/ItemDrop.tscn")

var all_item_base = preload("res://Ressources/ItemBases/AllItems.tres")

var stats_icons = [preload("res://Assets/2D/UI/stat_physical.png"), \
preload("res://Assets/2D/UI/stat_magic.png"), \
preload("res://Assets/2D/UI/stat_armor_physical.png"), \
preload("res://Assets/2D/UI/stat_armor_magic.png"), \
preload("res://Assets/2D/UI/stat_movement_speed.png"), \
preload("res://Assets/2D/UI/stat_souls.png"), \
preload("res://Assets/2D/UI/stat_cdr.png"), \
preload("res://Assets/2D/UI/stat_health_regen.png"), \
preload("res://Assets/2D/UI/stat_strength_regen.png"), \
preload("res://Assets/2D/UI/stat_max_health.png"), \
preload("res://Assets/2D/UI/stat_max_strength.png"), \
preload("res://Assets/2D/UI/stat_life_steal.png")]

@onready var camera := $Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var player_collision := $Collision
@onready var nav := $NavAgent
@onready var recall_visual := $RecallVisual
@onready var recall_timer := $Recall
@onready var hud := $CanvasLayer/HUD
@onready var scoreboard := $CanvasLayer/HUD/ScoreBoard
@onready var chat := $CanvasLayer/HUD/Chat
@onready var component_list := $CanvasLayer/HUD/Components/Pad/CompList
@onready var item_list = $CanvasLayer/HUD/Items/Pad/ItemList
@onready var ability_list = $CanvasLayer/HUD/ActionPanel/ItemBar/Pad/AbilityList
@onready var stats_list = $CanvasLayer/HUD/Stats/MarginContainer/StatList
@onready var channeling_bar := $CanvasLayer/HUD/ChannelingBar
@onready var mini_map := $CanvasLayer/HUD/MiniMap
@onready var abilities_machine := $PlayerModel/Abilities
@onready var workshop := $CanvasLayer/HUD/Workshop
@onready var workshop_item_list := $CanvasLayer/HUD/Workshop/ItemBoard/ItemListContainer/Pad/ItemList
@onready var workshop_item_inspection_icon := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemView
@onready var workshop_item_inspection_name := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemName
@onready var workshop_item_inspection_desc := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ItemDesc
@onready var workshop_item_inspection_comps := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/ComponentsNeeded
@onready var workshop_item_craft_button := $CanvasLayer/HUD/Workshop/ViewAndMake/Inspector/CraftItem
@onready var player_model := $PlayerModel
@onready var anims := $Anims
@onready var health_bar = $SubViewport/Infos/HealthBar
@onready var strength_bar = $SubViewport/Infos/StrengthBar
@onready var health_bar_hud = $CanvasLayer/HUD/ActionPanel/BarContainer/Pad/HealthBar
@onready var strength_bar_hud = $CanvasLayer/HUD/ActionPanel/BarContainer/Pad2/StrengthBar

#1 script pour le fog
#1 script pour la map
#1 script pour le workshop
#1 script pour l'hud

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	obtain_item(preload("res://Ressources/Items/HunterMachette.tres"))
	obtain_item(preload("res://Ressources/Items/BigSword.tres"))

func _physics_process(_delta) -> void:
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
	#var _vector_look = -Vector2().direction_to(get_viewport().get_mouse_position() * get_viewport().get_screen_transform().get_scale() - get_window().size/2.0)
	#player_model.look_at(Vector3(global_position.x + _vector_look.x, player_model.global_position.y, global_position.z + _vector_look.y))
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
	player_collision.disabled = false
	nav.target_position = global_position
	camera.global_position = camera_base_marker.global_position
	camera.top_level = false

func take_damage(damage : int, damage_type : int, _damage_dealer : Object) -> void:
	var _final_damage : int
	match damage_type:
		0:
			_final_damage = max(damage - physical_armor, 0.0)
		1:
			_final_damage = max(damage - magic_armor, 0.0)
		2:
			_final_damage = max(damage - physical_armor - magic_armor, 0.0)
	
	health = max(health - _final_damage, 0.0)
	update_info_bars()
	if is_dead():
		die()

func heal(healing : int) -> void:
	if !is_dead():
		health = min(health + healing, max_health)
		update_info_bars()

func lose_strength(strength_loss : int) -> void:
	if !is_dead():
		strength = max(strength - strength_loss, 0.0)
		update_info_bars()

func gain_strength(strength_gained) -> void:
	if !is_dead():
		strength = min(strength + strength_gained, max_strength)
		update_info_bars()

func update_info_bars() -> void:
	health_bar.value = float(health) / float(max_health) * 100.0
	health_bar_hud.value = float(health) / float(max_health) * 100.0
	strength_bar.value = float(strength) / float(max_strength) * 100.0
	strength_bar_hud.value = float(strength) / float(max_strength) * 100.0

func is_dead() -> bool:
	if health == 0:
		return true
	return false

func die() -> void:
	player_collision.disabled = true
	get_tree().create_timer(5.0).timeout.connect(Callable(func():
		health = max_health
		camera.top_level = true
		respawn_base()))

func movement() -> void:
	var input_dir = Vector2()
	if !nav.is_navigation_finished(): # Problème à regler sans doute pour les build release parce que le navigation met des fois un temps pour s'initialisé
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

func action_keys():
	if Input.is_action_just_released("left_click"):
		set_moving_map(false)
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
	
	#for i in range(8):
		#if Input.is_action_just_pressed("item"+str(i+1)):
			#item_selected = i
	for i in range(10):
		if Input.is_action_just_pressed("ability"+str(i+1)):
			if abilities[i]:
				if strength >= abilities[i].strength_cost:
					abilities_machine.use_ability(abilities[i], self)

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
	update_stats()
	update_abilities()
	update_items()

func update_abilities() -> void:
	# Clear ability bar
	for a_slot in ability_list.get_children():
		a_slot.queue_free()
	
	# Update abilities array
	var _abilities_had = []
	for i in items:
		for a in i.abilities:
			_abilities_had.append(a)
	for a in _abilities_had:
		if abilities.has(a):
			continue
		abilities[abilities.find(null)] = a
	for a in abilities:
		if !_abilities_had.has(a):
			abilities[abilities.find(a)] = null
			#Si il y a trop de sort pour l'instant ça va faire de la merde
	
	# Populate ability bar
	for a in range(abilities.size()):
		var _new_ability_hud = pre_ability_hud.instantiate()
		if abilities[a]:
			_new_ability_hud.ability = abilities[a]
		for i in InputMap.get_actions():
			if i.begins_with("ability") and i.ends_with(str(a+1)):
				_new_ability_hud.keybind = InputMap.action_get_events(i)[0].as_text()
		_new_ability_hud.connect("drag_ability", Callable(self, "drag_ability"))
		_new_ability_hud.connect("drop_ability", Callable(self, "drop_ability"))
		ability_list.add_child(_new_ability_hud)

var dragged_slot : Object
func drag_ability(slot : Object) -> void:
	dragged_slot = slot

func drop_ability(slot : Object) -> void:
	if dragged_slot:
		var _temp_ability = slot.ability
		abilities[ability_list.get_children().find(slot)] = dragged_slot.ability
		abilities[ability_list.get_children().find(dragged_slot)] = _temp_ability
		update_abilities()
		dragged_slot = null

func update_stats() -> void:
	physical_damage = BASE_PHYSICAL_DAMAGE
	magic_damage = BASE_MAGIC_DAMAGE
	physical_armor = BASE_PHYSICAL_ARMOR
	magic_armor = BASE_MAGIC_ARMOR
	movement_speed = DEFAULT_MOVEMENT_SPEED
	health_regeneration = BASE_HEALTH_REGENERATION + area_health_regeneration
	strength_regeneration = BASE_STRENGTH_REGENERATION
	max_health = BASE_MAX_HEALTH
	max_strength = BASE_MAX_STRENGTH
	for i in items:
		physical_damage += i.physical_damage
		magic_damage += i.magic_damage
		physical_armor += i.physical_armor
		magic_armor += i.magic_armor
		movement_speed += i.movement_speed
		cooldown_reduction += i.cooldown_reduction
		health_regeneration += i.health_regeneration
		strength_regeneration += i.strength_regeneration
		max_health += i.max_health
		max_strength += i.max_strength
		life_steal += i.life_steal
	
	var _stats = [physical_damage, magic_damage, physical_armor, magic_armor, movement_speed, \
	cooldown_reduction, health_regeneration, strength_regeneration, max_health, max_strength, life_steal]
	
	for i in stats_list.get_children():
		i.queue_free()
	
	for i in range(_stats.size()):
		var _new_stat_hud = pre_stat_hud.instantiate()
		_new_stat_hud.stat = str(_stats[i])
		_new_stat_hud.icon = stats_icons[i]
		stats_list.add_child(_new_stat_hud)

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
	update_stats()
	update_abilities()
	var _new_item_ground = pre_item_drop.instantiate()
	var _vector_drop = Vector2().direction_to(get_viewport().get_mouse_position() * get_viewport().get_screen_transform().get_scale() - get_window().size/2.0)
	_new_item_ground.position = Vector3(_vector_drop.x, 0.0, _vector_drop.y) * DROP_VECTOR_LENGTH + global_position
	_new_item_ground.item = item
	get_node("..").add_child(_new_item_ground)
	update_items()

func entering_workshop() -> void:
	area_health_regeneration = SPAWN_REGEN
	update_stats()
	in_workshop = true

func exit_workshop() -> void:
	area_health_regeneration = 0.0
	update_stats()
	in_workshop = false

func select_item(item : Item) -> void:
	item_workshop_selected = item
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
const FOG_RESOLUTION = 1
const FOG_TEXTURE_SIZE = Vector2i(int(MAP_SIZE.x), int(MAP_SIZE.y)) * FOG_RESOLUTION
const FOG_PLAYER_SIZE = Vector2i(15, 15) * FOG_RESOLUTION
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
	fog_map.blend_rect(_player_img, _player_img.get_used_rect(), _fog_position - _player_img.get_size()/2)
	mini_map.update_fog(fog_map, FOG_PLAYER_SIZE, global_position)
	density_tex.update([fog_map])
	get_node("..").get_node("FogOfWar").material.set("density_texture", density_tex)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_close_workshop_pressed() -> void:
	workshop.set_visible(false)

func _on_nav_agent_path_changed() -> void:
	mini_map.update_movement_line(nav)

func _on_update_movement_line_timeout() -> void:
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)
	update_map_fog()

func _on_recall_timeout() -> void:
	respawn_base()
	cancel_recall()

func _on_craft_item_pressed():
	if in_workshop:
		for c in range(item_workshop_selected.craft_recipe.size()):
			if item_workshop_selected.craft_recipe.values()[c] == components.get(item_workshop_selected.craft_recipe.keys()[c]):
				components.erase(item_workshop_selected.craft_recipe.keys()[c])
			else:
				var _new_quantity = components.get(item_workshop_selected.craft_recipe.keys()[c]) - item_workshop_selected.craft_recipe.values()[c]
				
				var _new_components = {item_workshop_selected.craft_recipe.keys()[c]:_new_quantity}
				components.merge(_new_components, true)
		update_components()
		update_workshop_inspection_tab(item_workshop_selected)

func _on_stat_regen_timeout():
	heal(int(health_regeneration))
	gain_strength(int(strength_regeneration))
