extends CharacterBody3D

# Controls
const ACCELERATION := 0.3
const CAMERA_MOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOVE_SPEED := 0.4
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.3
var target_direction := Vector3()

const EMPTY_MOVEMENT_SPEED := 4.0
const MAX_HEALTH_PER_LEVEL := 50.0
const PHYSICAL_DAMAGE_PER_LEVEL := 10.0
const MAGIC_DAMAGE_PER_LEVEL := 10.0
const MAX_XP_PER_LEVEL := 500
const RESPAWN_TIME_PER_LEVEL : float = 5.0
const KILL_REWARD_EXP := 750

# Statistics
var base_stats := {"physical_damage" : 1, \
"magic_damage" : 1, \
"physical_armor" : 1, \
"magic_armor" : 1, \
"movement_speed" : 3.0, \
"cooldown_reduction" : 0.0, \
"health_regeneration" : 2.0, \
"max_health" : 450, \
"life_steal" : 0.0, \
"souls" : 0}

var stats := base_stats.duplicate()

# Miscelious
var area_health_regeneration := 0.0

var health : int = base_stats.max_health
var souls := 0
var max_experience := MAX_XP_PER_LEVEL
var respawn_time : float = 5.0
var experience := 0
var level := 1

var recall := false

const SPAWN_REGEN = 100.0
var in_base := false

#var components := Dictionary()
#var items := [null, null, null, null, null, null, null, null]
var inventory : Array[ItemSlot] = [null, null, null, null, null, null, null, null, null, null, null, null]
var abilities := [null, null, null, null, null, null, null, null, null, null]

var can_move := true

@onready var world := get_node("..")
@onready var camera := $Camera
@onready var outline_camera := $Outline/OutlineVP/Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var player_collision := $Collision
@onready var hud := $CanvasLayer/HUD
@onready var nav := $Nav
@onready var vision := $Vision
@onready var ability_machine := $Abilities
@onready var effect_machine := $Effects
@onready var player_model := $PlayerModel
@onready var model_anims := $PlayerModel/AnimationPlayer
@onready var health_bar := $SubViewport/Infos/HealthBar
@onready var health_label := $CanvasLayer/HUD/ActionPanel/BarContainer/Pad/HealthLabel
@onready var level_label := $SubViewport/Infos/LevelPan/LevelLab

func _ready():
	add_to_group("player")
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	obtain_item(preload("res://Ressources/Items/recall_blob.tres"))
	obtain_item(preload("res://Ressources/Items/hunter_machette.tres"))
	obtain_item(preload("res://Ressources/Items/misfortune_broadsword.tres"))
	obtain_item(preload("res://Ressources/Items/stone_arquebus.tres"))
	obtain_item(preload("res://Ressources/Items/incandescent_book.tres"))
	obtain_item(preload("res://Ressources/Items/vision_staff.tres"))
	obtain_item(preload("res://Ressources/Items/beacon_bag.tres"))
	
	obtain_item(preload("res://Ressources/Items/vision_stone.tres"), 52)
	obtain_item(preload("res://Ressources/Items/golem_fragment.tres"), 3)
	obtain_item(preload("res://Ressources/Items/unstable_core.tres"), 3)
	obtain_item(preload("res://Ressources/Items/explosive_stone.tres"), 3)
	obtain_item(preload("res://Ressources/Items/floating_matter.tres"), 3)
	obtain_item(preload("res://Ressources/Items/essence_of_pain.tres"), 7)
	obtain_item(preload("res://Ressources/Items/essence_of_used_life.tres"), 3)
	
	add_effect(preload("res://Ressources/Effects/BindedFire.tres"), self)
	hud.update_info_bars()
	hud.update_abilities()
	hud.update_inventory()

func _physics_process(_delta) -> void:
	movement()
	action_keys()

func _process(delta):
	if camera.top_level:
		border_cam_movement(delta)
	update_camera_position()
	update_direction()
	check_for_target()
	
	outline_camera.global_transform = camera.global_transform

var hovered_target : Object
var selected_target : Object
func check_for_target() -> void:
	var _result = target_raycast()
	if _result.is_empty():
		DisplayServer.cursor_set_custom_image(Basics.cursors[Basics.CURSOR_MODE.NORMAL])
		if hovered_target == selected_target: return
		if hovered_target and hovered_target.has_method("stop_hovering_target"):
			hovered_target.stop_hovering_target()
		hovered_target = null
	else:
		if _result.get("collider") == self: return
		
		var _cursor = Basics.CURSOR_MODE.LOOT if hovered_target and hovered_target.is_dead() else Basics.CURSOR_MODE.ATTACK
		DisplayServer.cursor_set_custom_image(Basics.cursors[_cursor])
		
		if hovered_target and hovered_target != selected_target and hovered_target.has_method("stop_hovering_target"):
			hovered_target.stop_hovering_target()
		hovered_target = _result.get("collider")
		if hovered_target.has_method("hover_target"):
			hovered_target.hover_target()
			

const RAY_LENGTH := 100.0
func target_raycast() -> Dictionary:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		_ray_query.collision_mask = pow(2, 2-1) + pow(2, 3-1) # Set collision for player and monsters
		return get_world_3d().direct_space_state.intersect_ray(_ray_query)

func update_direction() -> void:
	if target_direction == Vector3():
		return
	player_model.look_at(-target_direction + Vector3(global_position.x, player_model.global_position.y, global_position.z))

const CAM_LIMITS = Rect2(Vector2(-63.0, -61.0), Vector2(63, 75))
func border_cam_movement(delta : float) -> void:
	if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_VISIBLE:
		return
	if get_viewport().get_mouse_position().x/1918.5 > 1 - get_viewport().size.x * CAMERA_MOVE_TRESHOLD:
		camera.global_position.x = min(camera.global_position.x + CAMERA_MOVE_SPEED * delta * 60.0, CAM_LIMITS.size.x)
	if get_viewport().get_mouse_position().x/1918.5 < get_viewport().size.x * CAMERA_MOVE_TRESHOLD:
		camera.global_position.x = max(camera.global_position.x - CAMERA_MOVE_SPEED * delta * 60.0, CAM_LIMITS.position.x)
	if get_viewport().get_mouse_position().y/1078.5 > 1 - get_viewport().size.y * CAMERA_MOVE_TRESHOLD:
		camera.global_position.z = min(camera.global_position.z + CAMERA_MOVE_SPEED * delta * 60.0, CAM_LIMITS.size.y)
	if get_viewport().get_mouse_position().y/1078.5 < get_viewport().size.y * CAMERA_MOVE_TRESHOLD:
		camera.global_position.z = max(camera.global_position.z - CAMERA_MOVE_SPEED * delta * 60.0, CAM_LIMITS.position.y)

var target_cam_pos = Vector2()
const CAMERA_SMOOTH_RATE = 0.7
func move_camera_by_minimap(pos : Vector2) -> void:
	target_cam_pos = pos

func update_camera_position() -> void:
	if dragged_by_map:
		camera.global_position.x = lerp(camera.global_position.x, clamp(target_cam_pos.x, CAM_LIMITS.position.x, CAM_LIMITS.size.x), CAMERA_SMOOTH_RATE)
		camera.global_position.z = lerp(camera.global_position.z, clamp(target_cam_pos.y, CAM_LIMITS.position.y, CAM_LIMITS.size.y), CAMERA_SMOOTH_RATE)

var dragged_by_map = false
func move_camera_click(press : bool) -> void:
	dragged_by_map = press
	camera.top_level = press
	if press:
		camera.position.x = clamp(target_cam_pos.x, CAM_LIMITS.position.x, CAM_LIMITS.size.x)
		camera.position.z = clamp(target_cam_pos.y, CAM_LIMITS.position.y, CAM_LIMITS.size.y)
	elif Input.is_action_pressed("center_cam"):
		camera.position = camera_base_marker.position

func _unhandled_input(event) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == 2:
			var _result = ability_machine.terrain_raycast()
			if !_result.is_empty():
				nav.target_position = _result.get("position")
				spawn_move_effect(_result.get("position"))
				ability_machine.cancel_abilities(Basics.ABILITY_CANCEL.MOVING)
		elif event.button_index == 1:
			var _result = target_raycast()
			if _result.is_empty():
				if selected_target and selected_target.has_method("lose_target"):
					selected_target.lose_target()
				selected_target = null
			else:
				if _result.get("collider") == self: return
				if selected_target and selected_target.has_method("lose_target"):
					selected_target.lose_target()
				selected_target = _result.get("collider")
				if selected_target.has_method("select_target"):
					selected_target.select_target()

var pre_move_effect = preload("res://Scenes/UI/click_move_effect.tscn")
func spawn_move_effect(pos : Vector3) -> void:
	var _new_move_effect = pre_move_effect.instantiate()
	_new_move_effect.position = pos
	world.add_child(_new_move_effect)

func respawn_base() -> void:
	global_position = get_node("..").get_node("NavMesh/Base/PlayerSpawn/1").global_position
	nav.target_position = global_position
	player_collision.disabled = false
	camera.global_position = camera_base_marker.global_position
	camera.top_level = false

func take_damage(damage : int, damage_type : int, damage_dealer : Object) -> void:
	if is_dead():
		return
	var _final_damage : int
	match damage_type:
		0:
			_final_damage = max(damage - stats.physical_armor, 0.0)
		1:
			_final_damage = max(damage - stats.magic_armor, 0.0)
		2:
			_final_damage = max(damage - stats.physical_armor - stats.magic_armor, 0.0)
	
	model_anims.play("take_damage")
	ability_machine.cancel_abilities(Basics.ABILITY_CANCEL.TAKING_DAMAGE)
	health = max(health - _final_damage, 0.0)
	hud.update_info_bars()
	if is_dead():
		damage_dealer.kill_player()
		die()

func kill_player() -> void:
	gain_experience(KILL_REWARD_EXP)
	souls += 1
	update_stats()

func heal(healing : int) -> void:
	if !is_dead():
		health = min(health + healing, stats.max_health)
		hud.update_info_bars()

func lose_experience(experience_loss : int) -> void:
	experience = experience - experience_loss
	if experience < 0 and level == 1:
		experience = 0
	while is_leveling_down():
		experience = max_experience - abs(experience)
		level -= 1
		respawn_time = level * RESPAWN_TIME_PER_LEVEL
		max_experience = level * MAX_XP_PER_LEVEL
	hud.update_info_bars()
	update_stats()

func gain_experience(experience_gained : int) -> void:
	experience = experience + experience_gained
	while is_leveling_up():
		experience = experience - max_experience
		level += 1
		respawn_time = level * RESPAWN_TIME_PER_LEVEL
		max_experience = level * MAX_XP_PER_LEVEL
	hud.update_info_bars()
	update_stats()

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

var dead_color_correction = preload("res://Ressources/ColorCorection/DeadColorCorrection.tres")
func die() -> void:
	can_move = false
	camera.top_level = true
	player_collision.disabled = true
	world.set_color_correction(dead_color_correction)
	get_tree().create_timer(respawn_time).timeout.connect(Callable(func():
		health = stats.max_health
		hud.update_info_bars()
		world.set_color_correction(null)
		player_collision.disabled = false
		can_move = true
		respawn_base()))

func movement() -> void:
	var input_dir = Vector2()
	#input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if !nav.is_navigation_finished() and input_dir == Vector2(): # Problème à regler sans doute pour les build release parce que le navigation met des fois un temps pour s'initialisé
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	else:
		nav.target_position = global_position
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and can_move:
		if model_anims.current_animation != "walk":
			model_anims.play("walk", 0.5, 0.3 * stats.movement_speed)
		if ability_machine.has_active_abilities():
			ability_machine.cancel_abilities(Basics.ABILITY_CANCEL.MOVING)
		velocity.x = lerp(velocity.x, direction.x * stats.movement_speed, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * stats.movement_speed, ACCELERATION)
		face_direction(direction)
	else:
		model_anims.play("idle_stand")
		velocity.x = lerp(velocity.x, 0.0, ACCELERATION)
		velocity.z = lerp(velocity.z, 0.0, ACCELERATION)
	
	move_and_slide()

func face_direction(direction : Vector3) -> void:
	target_direction = lerp(target_direction, direction, ROTATION_LERP_SPEED)

func action_keys():
	if Input.is_action_pressed("center_cam"):
		if !dragged_by_map:
			camera.top_level = false
			camera.position = camera_base_marker.position
	else:
		camera.top_level = true
	if Input.is_action_just_pressed("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_released("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_pressed("chat"):
		hud.chat.set_visible(!hud.chat.visible)
	for i in range(10):
		if Input.is_action_just_pressed("ability"+str(i+1)):
			if abilities[i]:
				match ability_machine.use_ability(abilities[i], self):
					Basics.ABILITY_ERROR.OK:
						if abilities[i].channeling:
							ability_machine.start_channeling(abilities[i].action_time, abilities[i].name)
						hud.ability_list.get_children()[i].use_ability()
		if Input.is_action_just_released("ability"+str(i+1)):
			if abilities[i]:
				ability_machine.release_ability(abilities[i])

func add_effect(effect : Effect, effect_dealer : Object) -> void:
	effect_machine.spawn_effect(effect, effect_dealer)
	if effect.duration > 0.0:
		get_tree().create_timer(effect.duration).timeout.connect(remove_effect.bind(effect))
	hud.update_effects()

func remove_effect(effect : Effect) -> void:
	effect_machine.destroy_effect(effect)
	hud.update_effects()

func has_passive(passive_id : String) -> bool:
	for i in inventory:
		if i:
			for p in i.item.passives:
				if p.id == passive_id:
					return true
	return false

func is_inventory_full() -> bool:
	return inventory.find(null) == -1

func obtain_item(item : Item, quantity : int = 1) -> void:
	var _item_slot = ItemSlot.new()
	_item_slot.item = item
	_item_slot.quantity = quantity
	inventory[inventory.find(null)] = _item_slot
	
	update_stats()
	hud.update_abilities()
	hud.update_inventory()

func lose_item(item : Item, quantity : int) -> void:
	var _item_slot = get_item_slot(item)
	_item_slot.quantity -= quantity
	if _item_slot.quantity <= 0:
		inventory[inventory.find(_item_slot)] = null
	
	update_stats()
	hud.update_abilities()
	hud.update_inventory()

func get_item_slot(itm : Item) -> ItemSlot:
	for i in inventory:
		if i.item == itm:
			return i
	return null

func has_item(itm : Item) -> bool:
	for i in inventory:
		if i.item == itm:
			return true
	return false

func entering_base() -> void:
	area_health_regeneration = SPAWN_REGEN
	update_stats()
	in_base = true
	hud.update_craft()

func exit_base() -> void:
	area_health_regeneration = 0.0
	update_stats()
	in_base = false
	hud.clear_craft()

func update_stats() -> void:
	# Set all stats to base value to recalculate
	stats = base_stats.duplicate()
	
	# Run fast when no items
	if inventory.count(null) == inventory.size():
		stats.movement_speed = EMPTY_MOVEMENT_SPEED
	
	# Add stats of levels
	stats.max_health += (level-1) * MAX_HEALTH_PER_LEVEL
	stats.physical_damage += (level-1) * PHYSICAL_DAMAGE_PER_LEVEL
	stats.magic_damage += (level-1) * MAGIC_DAMAGE_PER_LEVEL
	
	stats.souls = souls
	
	# Add regens areas
	stats.health_regeneration += area_health_regeneration
	
	# Add stats of items
	for i in inventory:
		if i == null:
			continue
		for s in range(i.item.stats.size()):
			stats[i.item.stats.keys()[s]] += i.item.stats.values()[s]
	hud.update_stats_hud()

func _on_nav_path_changed() -> void:
	hud.mini_map.update_movement_line(nav)

func _on_update_movement_line_timeout():
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)

func _on_stat_regen_timeout():
	heal(int(stats.health_regeneration))
