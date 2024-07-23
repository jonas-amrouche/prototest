extends CharacterBody3D

const DEFAULT_MOVEMENT_SPEED := 3.0
const HARVEST_MOVEMENT_SPEED := 1.0
const ACCELERATION := 0.3
const CAMERA_MOOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOOVE_SPEED := 0.5
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()

const PER_LEVEL_PLUS_EXPERIENCE := 1
const KILL_REWARD_EXP := 5

const BASE_PHYSICAL_DAMAGE := 50
const BASE_MAGIC_DAMAGE := 50
const BASE_PHYSICAL_ARMOR := 15
const BASE_MAGIC_ARMOR := 15
const BASE_HEALTH_REGENERATION := 2.0
const BASE_MAX_HEALTH := 450
const BASE_MAX_EXPERIENCE := 1
const BASE_LEVEL_MAX_EXPERIENCE := 16

var area_health_regeneration := 0.0

var physical_damage := BASE_PHYSICAL_DAMAGE
var magic_damage := BASE_MAGIC_DAMAGE
var physical_armor := BASE_PHYSICAL_ARMOR
var magic_armor := BASE_MAGIC_ARMOR
var movement_speed := DEFAULT_MOVEMENT_SPEED
var souls := 0
var cooldown_reduction := 0.0
var health_regeneration := BASE_HEALTH_REGENERATION
var max_health := BASE_MAX_HEALTH
var life_steal := 0.0
var health := max_health
var max_experience := BASE_MAX_EXPERIENCE
var experience := 0
var level := 1

var recall := false

const SPAWN_REGEN = 100.0
var in_workshop := false

var components := {}
var items := []
var abilities := [null, null, null, null, null, null, null, null, null, null]

var can_move := true

#var free_cam := false

var pre_item_drop = preload("res://Scenes/ItemDrop.tscn")

@onready var world := get_node("..")
@onready var camera := $Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var player_collision := $Collision
@onready var nav := $NavAgent
@onready var recall_visual := $RecallVisual
@onready var recall_timer := $Recall
@onready var hud := $CanvasLayer/HUD
@onready var abilities_machine := $Abilities
@onready var player_model := $PlayerModel
@onready var model_anims := $PlayerModel/AnimationPlayer
@onready var anims := $Anims
@onready var health_bar := $SubViewport/Infos/HealthBar
@onready var level_label := $SubViewport/Infos/LevelPan/LevelLab

#1 script pour le fog
#1 script pour la map
#1 script pour le workshop
#1 script pour l'hud

func _ready():
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	obtain_item(preload("res://Ressources/Items/HunterMachette.tres"))
	obtain_item(preload("res://Ressources/Items/BigSword.tres"))
	hud.update_info_bars()

func _physics_process(_delta) -> void:
	movement()
	action_keys()
	debug_features()

func _process(_delta):
	update_direction()

func update_direction() -> void:
		#var _vector_look = -Vector2().direction_to(get_viewport().get_mouse_position() * get_viewport().get_screen_transform().get_scale() - get_window().size/2.0)
		#abilities_machine.look_at(Vector3(global_position.x + _vector_look.x, abilities_machine.global_position.y, global_position.z + _vector_look.y))
	player_model.look_at(-target_direction + Vector3(global_position.x, player_model.global_position.y, global_position.z))

const CAM_LIMITS = Rect2(Vector2(-89.0, -89.0), Vector2(89, 95))
var move_camera = false
func cam_movement() -> void:
	if get_viewport().get_mouse_position().x/1918.5 > 1 - get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.x = min(camera.global_position.x + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.x)
	if get_viewport().get_mouse_position().x/1918.5 < get_viewport().size.x * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.x = max(camera.global_position.x - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.x)
	if get_viewport().get_mouse_position().y/1078.5 > 1 - get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.z = min(camera.global_position.z + CAMERA_MOOVE_SPEED, CAM_LIMITS.size.y)
	if get_viewport().get_mouse_position().y/1078.5 < get_viewport().size.y * CAMERA_MOOVE_TRESHOLD:
		camera.global_position.z = max(camera.global_position.z - CAMERA_MOOVE_SPEED, CAM_LIMITS.position.y)

func move_camera_by_minimap(pos : Vector2) -> void:
	if move_camera:
		camera.global_position.x = clamp(pos.x, CAM_LIMITS.position.x, CAM_LIMITS.size.x)
		camera.global_position.z = clamp(pos.y, CAM_LIMITS.position.y, CAM_LIMITS.size.y)

func set_move_camera(moving : bool) -> void:
	move_camera = moving
	camera.top_level = moving
	camera.position = camera_base_marker.position

func debug_features() -> void:
	if Input.is_action_just_pressed("quit_game"):
		get_tree().quit()
	if Input.is_action_just_pressed("fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_FULLSCREEN: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.WINDOW_MODE_WINDOWED: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	if Input.is_action_just_pressed("hide_ui"):
		hud.set_visible(!hud.visible)
	if Input.is_action_just_pressed("free_mouse"):
		match DisplayServer.mouse_get_mode():
			DisplayServer.MOUSE_MODE_CONFINED: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
			DisplayServer.MOUSE_MODE_VISIBLE: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)

#func _unhandled_input(event) -> void:
	#if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		#var _result = terrain_raycast(1)
		#if !_result.is_empty():
			#nav.target_position = _result.get("position")
			#if recall:
				#cancel_recall()

const RAY_LENGTH := 100.0
func terrain_raycast(col_mask : int) -> Dictionary:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		_ray_query.collision_mask = col_mask
		return get_world_3d().direct_space_state.intersect_ray(_ray_query)

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

func take_damage(damage : int, damage_type : int, damage_dealer : Object) -> void:
	var _final_damage : int
	match damage_type:
		0:
			_final_damage = max(damage - physical_armor, 0.0)
		1:
			_final_damage = max(damage - magic_armor, 0.0)
		2:
			_final_damage = max(damage - physical_armor - magic_armor, 0.0)
	
	model_anims.play("take_damage")
	health = max(health - _final_damage, 0.0)
	hud.update_info_bars()
	if is_dead():
		damage_dealer.gain_experience(KILL_REWARD_EXP)
		lose_experience(100)
		die()

func heal(healing : int) -> void:
	if !is_dead():
		health = min(health + healing, max_health)
		hud.update_info_bars()

func lose_experience(experience_loss : int) -> void:
	experience = experience - experience_loss
	if experience < 0 and level == 1:
		experience = 0
	while is_leveling_down():
		experience = max_experience - abs(experience)
		level -= 1
		max_experience = min(level * PER_LEVEL_PLUS_EXPERIENCE, BASE_LEVEL_MAX_EXPERIENCE)
	hud.update_info_bars()

func gain_experience(experience_gained : int) -> void:
	if !is_dead():
		experience = experience + experience_gained
		while is_leveling_up():
			experience = experience - max_experience
			level += 1
			max_experience = min(level * PER_LEVEL_PLUS_EXPERIENCE, BASE_LEVEL_MAX_EXPERIENCE)
		hud.update_info_bars()

func is_leveling_up() -> bool:
	if experience >= max_experience:
		return true
	return false

func is_leveling_down() -> bool:
	if experience < 0:
		return true
	return false

func is_dead() -> bool:
	if health == 0:
		return true
	return false

func die() -> void:
	can_move = false
	player_collision.disabled = true
	get_tree().create_timer(5.0).timeout.connect(Callable(func():
		health = max_health
		hud.update_info_bars()
		camera.top_level = true
		player_collision.disabled = false
		can_move = true
		respawn_base()))

func movement() -> void:
	var input_dir = Vector2()
	input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	#if !nav.is_navigation_finished(): # Problème à regler sans doute pour les build release parce que le navigation met des fois un temps pour s'initialisé
		#var _direction_result = global_position.direction_to(nav.get_next_path_position())
		#input_dir = Vector2(_direction_result.x, _direction_result.z)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	#var direction = Vector3(1.0, 0.0, 0.0)
	
	if direction and can_move:
		anims.play("walk", 1.0)
		cancel_recall()
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
	#if Input.is_action_just_released("left_click"):
		#set_move_camera(false)
	#if Input.is_action_just_pressed("decenter_cam"):
		#camera.top_level = true
		#free_cam = true
	#if Input.is_action_just_released("decenter_cam"):
		#free_cam = false
		#camera.global_position = camera_base_marker.global_position
		#camera.top_level = false
	if Input.is_action_just_pressed("recall"):
		nav.target_position = global_position
		recall = true
		recall_timer.start()
		start_channeling(recall_timer.wait_time)
		recall_visual.set_visible(true)
	if Input.is_action_just_pressed("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_released("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_pressed("chat"):
		hud.chat.set_visible(!hud.chat.visible)
	if Input.is_action_just_pressed("workshop"):
		hud.update_workshop_item_list(hud.category_selected)
		hud.workshop.set_visible(!hud.workshop.visible)
	for i in range(10):
		if Input.is_action_just_pressed("ability"+str(i+1)):
			if abilities[i]:
				match abilities_machine.use_ability(abilities[i], self):
					Basics.ABILITY_ERROR.OK:
						hud.ability_list.get_children()[i].use_ability()

var channeling_tween
func start_channeling(duration : float) -> void:
	hud.channeling_bar.set_visible(true)
	if channeling_tween:
		channeling_tween.kill()
	channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	channeling_tween.tween_method(Callable(hud.channeling_bar, "set_value"), 0.0, 100.0, duration)

func stop_channeling() -> void:
	hud.channeling_bar.set_visible(false)

func obtain_component(comp : Component, quantity : int) -> void:
	var _new_quantity = quantity
	if components.has(comp):
		var _old_quantity = components.get(comp)
		
		if _old_quantity:
			_new_quantity += _old_quantity
	
	var _new_components = {comp:_new_quantity}
	components.merge(_new_components, true)
	hud.update_components()

func lose_component(comp : Component, quantity : int) -> void:
	if quantity == components.get(comp):
		components.erase(comp)
	else:
		var _new_quantity = components.get(comp) - quantity
		var _new_components = {comp:_new_quantity}
		components.merge(_new_components, true)
	hud.update_components()

func obtain_item(item : Item) -> void:
	items.append(item)
	update_stats()
	hud.update_abilities()
	hud.update_items()

func entering_workshop() -> void:
	area_health_regeneration = SPAWN_REGEN
	update_stats()
	in_workshop = true

func exit_workshop() -> void:
	area_health_regeneration = 0.0
	update_stats()
	in_workshop = false

func update_stats() -> void:
	physical_damage = BASE_PHYSICAL_DAMAGE
	magic_damage = BASE_MAGIC_DAMAGE
	physical_armor = BASE_PHYSICAL_ARMOR
	magic_armor = BASE_MAGIC_ARMOR
	movement_speed = DEFAULT_MOVEMENT_SPEED
	health_regeneration = BASE_HEALTH_REGENERATION + area_health_regeneration
	max_health = BASE_MAX_HEALTH
	for i in items:
		physical_damage += i.physical_damage
		magic_damage += i.magic_damage
		physical_armor += i.physical_armor
		magic_armor += i.magic_armor
		movement_speed += i.movement_speed
		cooldown_reduction += i.cooldown_reduction
		health_regeneration += i.health_regeneration
		max_health += i.max_health
		life_steal += i.life_steal
	hud.update_stats_hud()

const DROP_VECTOR_LENGTH = 1.4
func drop_item(item : Item) -> void:
	items.remove_at(items.find(item))
	update_stats()
	hud.update_abilities()
	var _new_item_ground = pre_item_drop.instantiate()
	var _vector_drop = Vector2().direction_to(get_viewport().get_mouse_position() * get_viewport().get_screen_transform().get_scale() - get_window().size/2.0)
	_new_item_ground.position = Vector3(_vector_drop.x, 0.0, _vector_drop.y) * DROP_VECTOR_LENGTH + global_position
	_new_item_ground.item = item
	get_node("..").add_child(_new_item_ground)
	hud.update_items()

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

#func _on_nav_agent_path_changed() -> void:
	#hud.mini_map.update_movement_line(nav)

func _on_recall_timeout() -> void:
	respawn_base()
	cancel_recall()

func _on_stat_regen_timeout():
	heal(int(health_regeneration))
