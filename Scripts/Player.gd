extends CharacterBody3D

# Controls
const ACCELERATION := 0.3
const CAMERA_MOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOVE_SPEED := 0.25
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.3
var target_direction := Vector3()

const EMPTY_MOVEMENT_SPEED := 4.0
const MAX_HEALTH_PER_LEVEL := 50.0
const PHYSICAL_DAMAGE_PER_LEVEL := 10.0
const MAGIC_DAMAGE_PER_LEVEL := 10.0
const LEVEL_MAX_EXPERIENCE := 16
const KILL_REWARD_EXP := 10

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
var max_experience := 1
var experience := 0
var level := 1

var recall := false

const SPAWN_REGEN = 100.0
var in_base := false

var components := Dictionary()
var items := [null, null, null, null, null, null, null, null]
var abilities := [null, null, null, null, null, null, null, null, null, null]

var can_move := true

@onready var world := get_node("..")
@onready var camera := $Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var player_collision := $Collision
@onready var recall_visual := $RecallVisual
@onready var recall_timer := $Recall
@onready var hud := $CanvasLayer/HUD
@onready var nav := $Nav
@onready var vision := $Vision
@onready var ability_machine := $Abilities
@onready var effect_machine := $Effects
@onready var player_model := $PlayerModel
@onready var model_anims := $PlayerModel/AnimationPlayer
@onready var health_bar := $SubViewport/Infos/HealthBar
@onready var level_label := $SubViewport/Infos/LevelPan/LevelLab

func _ready():
	add_to_group("player")
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	obtain_component(preload("res://Ressources/Components/Wood.tres"), 3)
	obtain_component(preload("res://Ressources/Components/Metal.tres"), 3)
	obtain_component(preload("res://Ressources/Components/VisionStone.tres"), 52)
	obtain_component(preload("res://Ressources/Components/GolemFragment.tres"), 3)
	obtain_component(preload("res://Ressources/Components/EssenceOfLife.tres"), 3)
	obtain_component(preload("res://Ressources/Components/EssenceOfPain.tres"), 7)
	obtain_component(preload("res://Ressources/Components/FloatingMatter.tres"), 3)
	obtain_component(preload("res://Ressources/Components/UnstableCore.tres"), 3)
	obtain_component(preload("res://Ressources/Components/ExplosiveStone.tres"), 3)
	obtain_item(preload("res://Ressources/Items/hunter_machette.tres"))
	obtain_item(preload("res://Ressources/Items/misfortune_broadsword.tres"))
	obtain_item(preload("res://Ressources/Items/stone_arquebus.tres"))
	obtain_item(preload("res://Ressources/Items/incandescent_book.tres"))
	obtain_item(preload("res://Ressources/Items/vision_staff.tres"))
	obtain_item(preload("res://Ressources/Items/beacon_bag.tres"))
	add_effect(preload("res://Ressources/Effects/BindedFire.tres"), self)
	hud.update_info_bars()
	hud.update_components()
	hud.update_abilities()
	hud.update_items()
	hud.update_craft_available()

func _physics_process(_delta) -> void:
	movement()
	action_keys()

func _process(delta):
	if camera.top_level:
		border_cam_movement(delta)
	update_camera_position()
	update_direction()

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
	if event is InputEventMouseButton and event.button_index == 2 and event.pressed:
		var _result = ability_machine.terrain_raycast()
		if !_result.is_empty():
			nav.target_position = _result.get("position")
			spawn_move_effect(_result.get("position"))
			if recall:
				cancel_recall()

var pre_move_effect = preload("res://Scenes/UI/click_move_effect.tscn")
func spawn_move_effect(pos : Vector3) -> void:
	var _new_effect = pre_move_effect.instantiate()
	_new_effect.position = pos
	world.add_child(_new_effect)
	get_tree().create_timer(0.5).timeout.connect(func():
		_new_effect.queue_free())

func cancel_recall() -> void:
	recall_timer.stop()
	recall = false
	stop_channeling()
	recall_visual.set_visible(false)

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
		max_experience = min(level, LEVEL_MAX_EXPERIENCE)
	hud.update_info_bars()
	update_stats()

func gain_experience(experience_gained : int) -> void:
	experience = experience + experience_gained
	while is_leveling_up():
		experience = experience - max_experience
		level += 1
		max_experience = min(level, LEVEL_MAX_EXPERIENCE)
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
	get_tree().create_timer(5.0).timeout.connect(Callable(func():
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
		cancel_recall()
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
	for i in range(10):
		if Input.is_action_just_pressed("ability"+str(i+1)):
			if abilities[i]:
				match ability_machine.use_ability(abilities[i], self):
					Basics.ABILITY_ERROR.OK:
						hud.ability_list.get_children()[i].use_ability()
		if Input.is_action_just_released("ability"+str(i+1)):
			if abilities[i]:
				ability_machine.release_ability(abilities[i], self)

func add_effect(effect : Effect, effect_dealer : Object) -> void:
	effect_machine.spawn_effect(effect, effect_dealer)
	if effect.duration > 0.0:
		get_tree().create_timer(effect.duration).timeout.connect(remove_effect.bind(effect))
	hud.update_effects()

func remove_effect(effect : Effect) -> void:
	effect_machine.destroy_effect(effect)
	hud.update_effects()

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
	if components.has(comp):
		components[comp] += quantity
	else:
		components[comp] = quantity
	
	hud.update_components()
	hud.update_craft_available()

func has_component(component_name : String) -> bool:
	for i in range(components.size()):
		if components.values[i].name == component_name:
			return true
	return false

func has_passive(passive_id : String) -> bool:
	for i in items:
		if i:
			for p in i.passives:
				if p.id == passive_id:
					return true
	return false

func lose_component(comp : Component, quantity : int) -> void:
	if components[comp] == quantity:
		components.erase(comp)
	else:
		components[comp] -= quantity
	hud.update_components()

func is_items_full() -> bool:
	return items.find(null) == -1

func obtain_item(item : Item) -> void:
	items[items.find(null)] = item
	
	update_stats()
	hud.update_abilities()
	hud.update_items()
	hud.update_craft_available()

func lose_item(item : Item) -> void:
	items[items.find(item)] = null
	
	update_stats()
	hud.update_abilities()
	hud.update_items()

func entering_base() -> void:
	area_health_regeneration = SPAWN_REGEN
	update_stats()
	hud.update_craft_available()
	in_base = true
	hud.craft_tab.show()
	hud.decompose_tab.show()
	hud.update_decompose()

func exit_base() -> void:
	area_health_regeneration = 0.0
	update_stats()
	in_base = false
	hud.craft_tab.hide()
	hud.decompose_tab.hide()
	hud.clear_decompose()

func update_stats() -> void:
	# Set all stats to base value to recalculate
	stats = base_stats.duplicate()
	
	# Run fast when no items
	if items.count(null) == items.size():
		stats.movement_speed = EMPTY_MOVEMENT_SPEED
	
	# Add stats of levels
	stats.max_health += (level-1) * MAX_HEALTH_PER_LEVEL
	stats.physical_damage += (level-1) * PHYSICAL_DAMAGE_PER_LEVEL
	stats.magic_damage += (level-1) * MAGIC_DAMAGE_PER_LEVEL
	
	stats.souls = souls
	
	# Add regens areas
	stats.health_regeneration += area_health_regeneration
	
	# Add stats of items
	for i in items:
		if i == null:
			continue
		for s in range(i.stats.size()):
			stats[i.stats.keys()[s]] += i.stats.values()[s]
	hud.update_stats_hud()

func is_item_craftable(item : Item) -> bool:
	var _component_had = 0
	for r in range(item.craft_recipe.size()):
		for c in range(components.size()):
			if item.craft_recipe.keys()[r] == components.keys()[c]:
				if item.craft_recipe.values()[r] <= components.values()[c]:
					_component_had += 1
	if _component_had == item.craft_recipe.size():
		return true
	return false

func _on_nav_path_changed() -> void:
	hud.mini_map.update_movement_line(nav)

func _on_update_movement_line_timeout():
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)

func _on_recall_timeout() -> void:
	respawn_base()
	cancel_recall()

func _on_stat_regen_timeout():
	heal(int(stats.health_regeneration))
