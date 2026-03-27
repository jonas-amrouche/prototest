extends CharacterBody3D

@onready var world := get_parent()
@onready var base_entity : Entity = world.resources.player_entity.duplicate()
@onready var entity : Entity = base_entity.duplicate()

# Controls
const ACCELERATION := 0.3
const CAMERA_MOVE_TRESHOLD := 1.0/100000.0
const CAMERA_MOVE_SPEED := 0.4
const CAMERA_LERP_SPEED := 0.75
const ROTATION_LERP_SPEED := 0.3
const CAMERA_BASE_FOV := 50.0
const CAMERA_MIN_FOV := 10.0
const CAMERA_ZOOM_SPEED := 20.0
var target_fov := CAMERA_BASE_FOV
var target_direction := Vector3()

const EMPTY_MOVEMENT_SPEED := 120
const LOOT_RANGE := 1.0
const MAX_HEALTH_PER_LEVEL := 50
const PHYSICAL_DAMAGE_PER_LEVEL := 10
const MAGIC_DAMAGE_PER_LEVEL := 10
const MAX_XP_PER_LEVEL := 500
const SLOT_PER_LEVEL := 1
const RESPAWN_TIME_PER_LEVEL : float = 5.0
const KILL_REWARD_EXP := 750

# Miscelious
var area_health_regeneration := 0

var max_experience := MAX_XP_PER_LEVEL
var respawn_time : float = 5.0
var experience := 0
var level := 1

const SPAWN_REGEN := 98
var in_base := false

# INVENTORY
const INVENTORY_SIZE := 16
var inventory : Array[ItemSlot]

# CONSUMABLES
const CONSUMABLES_BASE_SIZE := 2
const CONSUMABLES_MAX_SIZE := 6
var consumables_size = CONSUMABLES_BASE_SIZE
var consumables : Array[ItemSlot]

# CRAFTS
const CRAFT_MAX_SIZE := 3
var craft_size = CRAFT_MAX_SIZE
var crafts : Array[ItemSlot]

var abilities : Array[Ability]

var can_move := true
var can_cast := true

var hovered_target : Object
var selected_target : Object
var cursor_mode : Basics.CursorMode

var auto_attack_target : Object
var loot_target : Object

@onready var camera := $Camera
@onready var hover_outline_vpc := $HoverOutline
@onready var hover_outline_camera := $HoverOutline/HoverOutlineVP/Camera
@onready var select_outline_vpc := $SelectOutline
@onready var select_outline_camera := $SelectOutline/SelectOutlineVP/Camera
@onready var camera_base_marker := $CameraBaseMarker
@onready var player_collision := $Collision
@onready var hud := $CanvasLayer/HUD
@onready var nav := $Nav
@onready var vision := $Vision
@onready var ability_machine := $Abilities
@onready var effect_machine := $Effects
@onready var player_model := $PlayerModel
@onready var health_bar := $SubViewport/PlayerHealthBar/HealthBar
@onready var pseudo_lab := $SubViewport/PlayerHealthBar/PseudoLab
@onready var model_anims := $PlayerModel/AnimationPlayer
#@onready var level_label := $SubViewport/PlayerHealthBar/LevelPan/LevelLab
@onready var debug_range := $DebugRange

func _enter_tree() -> void:
	set_multiplayer_authority(name.to_int())

func _ready():
	vision.initialize_fog(world.generated_data)
	entity.set_full_health()
	add_to_group("player")
	camera.current = is_multiplayer_authority()
	hover_outline_vpc.set_visible(is_multiplayer_authority())
	select_outline_vpc.set_visible(is_multiplayer_authority())
	set_process_input(is_multiplayer_authority())
	set_process_unhandled_input(is_multiplayer_authority())
	
	DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	inventory = fill_inventory(INVENTORY_SIZE)
	consumables = fill_consumables(CONSUMABLES_MAX_SIZE)
	crafts = fill_crafts(CRAFT_MAX_SIZE)
	obtain_item(preload("res://Resources/Items/hunter_machette.tres"))
	obtain_item(preload("res://Resources/Items/aliane_potion.tres"), 3)
	hud.bind_default_abilities()
	#print(Replication.players[int(name)])
	pseudo_lab.text = Replication.players[int(name)]["name"]
	#obtain_item(preload("res://Resources/Items/ascendant_archirune.tres"))
	#obtain_item(preload("res://Resources/Items/misfortune_broadsword.tres"))
	#obtain_item(preload("res://Resources/Items/incandescent_pages.tres"))
	#obtain_item(preload("res://Resources/Items/stone_arquebus.tres"))
	#obtain_item(preload("res://Resources/Items/vision_staff.tres"))
	#obtain_item(preload("res://Resources/Items/blue_trinket.tres"))
	#obtain_item(preload("res://Resources/Items/infinitrinket.tres"))
	#obtain_item(preload("res://Resources/Items/leather_pouch.tres"))
	
	#obtain_item(preload("res://Resources/Items/vision_stone.tres"), 52)
	#obtain_item(preload("res://Resources/Items/weak_flame.tres"), 3)
	#obtain_item(preload("res://Resources/Items/golem_fragment.tres"), 3)
	#obtain_item(preload("res://Ressources/Items/unstable_core.tres"), 3)
	#obtain_item(preload("res://Ressources/Items/explosive_stone.tres"), 3)
	#obtain_item(preload("res://Ressources/Items/floating_matter.tres"), 3)
	#obtain_item(preload("res://Ressources/Items/essence_of_pain.tres"), 7)
	#obtain_item(preload("res://Ressources/Items/essence_of_used_life.tres"), 3)
	
	#add_effect(preload("res://Resources/Effects/BindedFire.tres"), self)
	update_items()
	update_stats()
	hud.update_info_bars()
	hud.update_abilities()

func _physics_process(_delta) -> void:
	movement()
	action_keys()

func _process(delta):
	if DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CONFINED and is_multiplayer_authority():
		border_cam_movement(delta)
		update_camera_position()
		check_for_target()
	update_direction()
	update_camera_zoom(delta)
	auto_attacking()
	looting()
	
	hover_outline_camera.global_transform = camera.global_transform
	select_outline_camera.global_transform = camera.global_transform

func update_camera_zoom(delta : float) -> void:
	camera.fov = lerp(camera.fov, target_fov, CAMERA_ZOOM_SPEED * delta)
	hover_outline_camera.fov = lerp(hover_outline_camera.fov, target_fov, CAMERA_ZOOM_SPEED * delta)
	select_outline_camera.fov = lerp(select_outline_camera.fov, target_fov, CAMERA_ZOOM_SPEED * delta)

var loot_timer : SceneTreeTimer
func looting() -> void:
	if loot_target:
		var _loot_pos = Vector2(loot_target.global_position.x, loot_target.global_position.z)
		var _player_pos = Vector2(global_position.x, global_position.z)
		if _player_pos.distance_to(_loot_pos) < LOOT_RANGE:
			if loot_target.entity.entity_type == Basics.EntityType.ITEM:
				obtain_item(loot_target.item, loot_target.quantity)
				loot_target.loot_item()
				loot_target = null
			else:
				if loot_timer:
					return
				loot_timer = get_tree().create_timer(1.0)
				nav.target_position = global_position
				ability_machine.start_channeling(1.0, "Looting")
				loot_timer.timeout.connect(loot_corpse.bind())
	else:
		if loot_timer and loot_timer.timeout.is_connected(loot_corpse):
			loot_timer.timeout.disconnect(loot_corpse)
			ability_machine.stop_channeling()
			loot_timer = null

func loot_corpse() -> void:
	hud.open_and_display_loot(loot_target.loot)
	for lo in loot_target.loot:
		obtain_item(lo.item, lo.quantity)
	loot_target.loot_body()
	loot_target = null
	loot_timer = null

func auto_attacking() -> void:
	if auto_attack_target:
		if auto_attack_target.is_dead():
			auto_attack_target = null
			return
		nav.target_position = auto_attack_target.global_position
		var _auto_ability : Ability = null
		# TODO : auto ability should be set to the class ability
		if _auto_ability and ability_machine.is_in_range(_auto_ability):
			nav.target_position = global_position
			
			if ability_machine.use_ability(_auto_ability, self) == Basics.AbilityError.OK and _auto_ability.channeling:
				ability_machine.start_channeling(_auto_ability.action_time, _auto_ability.id.capitalize())
			if _auto_ability.spell_range == 0.0:
				nav.target_position = global_position

func check_for_target() -> void:
	var _result = target_raycast()
	if _result.is_empty() or _result.get("collider") == self:
		cursor_mode = Basics.CursorMode.NORMAL
		DisplayServer.cursor_set_custom_image(world.resources.cursors[cursor_mode])
		if hovered_target and hovered_target.has_method("stop_hovering_target"):
			hovered_target.stop_hovering_target()
			hud.update_target()
		hovered_target = null
	else:
		if hovered_target and hovered_target.has_method("stop_hovering_target"):
			hovered_target.stop_hovering_target()
			hud.update_target()
		
		hovered_target = _result.get("collider")
		
		match hovered_target.entity.entity_type:
			Basics.EntityType.ITEM:
				cursor_mode = Basics.CursorMode.LOOT
			Basics.EntityType.MONSTER, Basics.EntityType.PLAYER:
				cursor_mode = Basics.CursorMode.LOOT if hovered_target and hovered_target.is_dead() else Basics.CursorMode.ATTACK
			Basics.EntityType.NPCS:
				cursor_mode = Basics.CursorMode.NORMAL
		DisplayServer.cursor_set_custom_image(world.resources.cursors[cursor_mode])
		
		if hovered_target.has_method("hover_target"):
			hovered_target.hover_target()
			hud.update_target()

const RAY_LENGTH := 100.0
func target_raycast() -> Dictionary:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.exclude = [get_rid()]
		_ray_query.collide_with_areas = true
		_ray_query.from = camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		_ray_query.collision_mask = pow(2, 2-1) + pow(2, 3-1) + pow(2, 5-1) + pow(2, 6-1) + pow(2, 7-1) # Set collision for player and monsters
		return get_world_3d().direct_space_state.intersect_ray(_ray_query)

func update_direction() -> void:
	if target_direction == Vector3():
		return
	player_model.look_at(-target_direction + Vector3(global_position.x, player_model.global_position.y, global_position.z))

const CAM_LIMITS = Rect2(Vector2(-63.0, -61.0), Vector2(63, 75))
func border_cam_movement(delta : float) -> void:
	if camera.top_level:
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

var outline_tween : Tween
func _unhandled_input(event) -> void:
	if event is InputEventMouseButton and DisplayServer.mouse_get_mode() == DisplayServer.MOUSE_MODE_CONFINED:
		if event.button_index == 2 and event.pressed:
			if hovered_target:
				match cursor_mode:
					Basics.CursorMode.ATTACK:
						auto_attack_target = hovered_target
					Basics.CursorMode.LOOT:
						loot_target = hovered_target
						nav.target_position = loot_target.global_position
				if outline_tween:
					outline_tween.kill()
				outline_tween = get_tree().create_tween()
				hover_outline_vpc.material.set_shader_parameter("outline_size", 0.5)
				outline_tween.tween_property(hover_outline_vpc.material, "shader_parameter/outline_size", 0.05, 0.3)
			else:
				var _result = ability_machine.terrain_raycast()
				if !_result.is_empty():
					auto_attack_target = null
					loot_target = null
					nav.target_position = _result.get("position")
					spawn_move_effect(_result.get("position"))
					ability_machine.cancel_abilities(Basics.AbilityCancel.MOVING)
		elif event.button_index == 1 and event.pressed:
			var _result = target_raycast()
			if _result.is_empty():
				if selected_target and selected_target.has_method("lose_target"):
					selected_target.lose_target()
					if selected_target.entity.state_changed.is_connected(Callable(hud, "update_target")):
						selected_target.entity.state_changed.disconnect(Callable(hud, "update_target"))
				selected_target = null
				hud.update_target()
			else:
				if _result.get("collider") == self: return
				if selected_target and selected_target.has_method("lose_target"):
					selected_target.lose_target()
					if selected_target.entity.state_changed.is_connected(Callable(hud, "update_target")):
						selected_target.entity.state_changed.disconnect(Callable(hud, "update_target"))
					hud.update_target()
				selected_target = _result.get("collider")
				if selected_target.has_method("select_target"):
					selected_target.select_target()
					if !selected_target.entity.state_changed.is_connected(Callable(hud, "update_target")):
						selected_target.entity.state_changed.connect(Callable(hud, "update_target"))
					hud.update_target()
		elif event.button_index == 1 and !event.pressed and hud.dragged_item_ref:
			if hud.dragged_item_ref.item_slot.item:
				drop_item_ground(hud.dragged_item_ref.item_slot)

#const DROP_VECTOR_LENGTH = 1.4
func drop_item_ground(item_slot : ItemSlot) -> void:
	var _new_item_ground = world.resources.item_ground.instantiate()
	#var _vector_drop = Vector2().direction_to(get_viewport().get_mouse_position() * get_viewport().get_screen_transform().get_scale() - get_window().size/2.0)
	#_new_item_ground.position = Vector3(_vector_drop.x, 0.0, _vector_drop.y) * DROP_VECTOR_LENGTH + global_position
	_new_item_ground.position = global_position
	_new_item_ground.item = item_slot.item
	_new_item_ground.quantity = item_slot.quantity
	item_slot.item = null
	item_slot.quantity = 0
	world.items.add_child(_new_item_ground)
	update_items()
	update_stats()
	hud.update_abilities()

func spawn_move_effect(pos : Vector3) -> void:
	var _new_move_effect = world.resources.move_effect.instantiate()
	_new_move_effect.position = pos
	world.add_child(_new_move_effect)

func respawn_base() -> void:
	global_position = get_node("..").get_node("NavMesh/Base/PlayerSpawn/1").global_position
	nav.target_position = global_position
	player_collision.disabled = false
	camera.global_position = camera_base_marker.global_position
	camera.top_level = false

func take_damage(damage : int, damage_type : Basics.DamageType, damage_dealer : Object) -> void:
	if is_dead():
		return
	var _armor : int
	match damage_type:
		Basics.DamageType.PHYSICAL:
			_armor = entity.get_physical_armor()
		Basics.DamageType.TENSION:
			_armor = entity.get_tension_armor()
		Basics.DamageType.WITHERING:
			_armor = entity.get_withering_armor()
	var _final_damage : int = max(damage - _armor, 0)

	model_anims.play("take_damage")
	ability_machine.cancel_abilities(Basics.AbilityCancel.TAKING_DAMAGE)
	entity.set_health(entity.health - _final_damage)
	hud.update_info_bars()
	if is_dead():
		damage_dealer.kill_player()
		die()

func kill_player() -> void:
	gain_experience(KILL_REWARD_EXP)
	entity.souls += 1
	update_stats()

func heal(healing : int) -> void:
	if !is_dead():
		entity.set_health(entity.health + healing)
		hud.update_info_bars()

func lose_experience(experience_loss : int) -> void:
	experience = experience - experience_loss
	if experience < 0 and level == 1:
		experience = 0
	while is_leveling_down():
		experience = max_experience - abs(experience)
		level -= 1
		respawn_time = level * RESPAWN_TIME_PER_LEVEL
		consumables_size = min(CONSUMABLES_BASE_SIZE + floor(float(level-3)/3.0), CONSUMABLES_MAX_SIZE)
		max_experience = level * MAX_XP_PER_LEVEL
	hud.update_info_bars()
	hud.update_inventory()
	update_stats()

func gain_experience(experience_gained : int) -> void:
	experience = experience + experience_gained
	while is_leveling_up():
		experience = experience - max_experience
		level += 1
		respawn_time = level * RESPAWN_TIME_PER_LEVEL
		consumables_size = min(CONSUMABLES_BASE_SIZE + floor(float(level-3)/3.0), CONSUMABLES_MAX_SIZE)
		max_experience = level * MAX_XP_PER_LEVEL
	hud.update_info_bars()
	hud.update_inventory()
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
	if entity.health <= 0:
		return true
	return false

func die() -> void:
	can_move = false
	clear_craft()
	camera.top_level = true
	player_collision.disabled = true
	world.set_color_correction(world.resources.dead_color_correction)
	get_tree().create_timer(respawn_time).timeout.connect(Callable(func():
		entity.set_full_health()
		hud.update_info_bars()
		world.set_color_correction(null)
		player_collision.disabled = false
		can_move = true
		respawn_base()))

func movement() -> void:
	var input_dir = Vector2()
	if !nav.is_navigation_finished() and input_dir == Vector2(): # Problème à regler sans doute pour les build release parce que le navigation met des fois un temps pour s'initialisé
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	else:
		nav.target_position = global_position
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if direction and can_move:
		if model_anims.current_animation != "walk":
			model_anims.play("walk", 0.5, 0.3 * entity.get_movement_speed()/40.0)
		if ability_machine.has_active_abilities():
			ability_machine.cancel_abilities(Basics.AbilityCancel.MOVING)
		velocity.x = lerp(velocity.x, direction.x * entity.get_movement_speed()/40.0, ACCELERATION)
		velocity.z = lerp(velocity.z, direction.z * entity.get_movement_speed()/40.0, ACCELERATION)
		#if auto_attack_target:
			#face_direction(global_position.direction_to(Vector3(auto_attack_target.global_position.x, global_position.y, auto_attack_target.global_position.z)))
		#else:
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
	if Input.is_action_just_pressed("zoom_in"):
		target_fov = max(target_fov - 5.0, CAMERA_MIN_FOV)
	if Input.is_action_just_pressed("zoom_out"):
		target_fov = min(target_fov + 5.0, CAMERA_BASE_FOV)
	if Input.is_action_just_pressed("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_released("show_scoreboard"):
		hud.scoreboard.set_visible(!hud.scoreboard.visible)
	if Input.is_action_just_pressed("workshop"):
		hud.update_workshop()
		hud.workshop_tab.visible = !hud.workshop_tab.visible
	if Input.is_action_just_pressed("recall"):
		var _recall = world.resources.recall_ability
		if ability_machine.use_ability(_recall, self) == Basics.AbilityError.OK:
			ability_machine.start_channeling(_recall.action_time, _recall.id.capitalize())
	if Input.is_action_just_pressed("chat"):
		hud.chat.set_visible(!hud.chat.visible)
		can_cast = hud.chat.visible
	for i in range(abilities.size()):
		if abilities[i] and can_cast and abilities[i].slot_id >= 0 and abilities[i].slot_id < 10:
			if Input.is_action_just_pressed("ability"+str(abilities[i].slot_id+1)):
				match ability_machine.use_ability(abilities[i], self):
					Basics.AbilityError.OK:
						if abilities[i].channeling:
							ability_machine.start_channeling(abilities[i].action_time, abilities[i].id.capitalize())
						hud.ability_list.get_children()[abilities[i].slot_id].use_ability()
			if Input.is_action_just_released("ability"+str(abilities[i].slot_id+1)):
				ability_machine.release_ability(abilities[i])
	
	for i in range(consumables.size()):
		if consumables[i].item and can_cast:
			if Input.is_action_just_pressed("consumable"+str(consumables[i].slot_id+1)):
				var ability = consumables[i].item.abilities[0]
				match ability_machine.use_ability(ability, self):
					Basics.AbilityError.OK:
						lose_item(consumables[i].item, 1)
						if abilities[i].channeling:
							ability_machine.start_channeling(ability.action_time, ability.id.capitalize())

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
		if !i.item: continue
		for p in i.item.passives:
			if p.id == passive_id:
				return true
	return false

func fill_inventory(max_size : int) -> Array[ItemSlot]:
	var _inv : Array[ItemSlot]
	for i in range(max_size):
		var _new_item_slot = ItemSlot.new()
		_new_item_slot.slot_type = Basics.SlotType.INVENTORY
		_new_item_slot.slot_id = i
		_inv.push_back(_new_item_slot)
	return _inv

func fill_consumables(max_size : int) -> Array[ItemSlot]:
	var _cons : Array[ItemSlot]
	for i in range(max_size):
		var _new_item_slot = ItemSlot.new()
		_new_item_slot.slot_type = Basics.SlotType.CONSUMABLE
		_new_item_slot.slot_id = i
		_cons.push_back(_new_item_slot)
	return _cons

func fill_crafts(max_size : int) -> Array[ItemSlot]:
	var _cra : Array[ItemSlot]
	for i in range(max_size):
		var _new_item_slot = ItemSlot.new()
		_new_item_slot.slot_type = Basics.SlotType.CRAFT
		_new_item_slot.slot_id = i
		_cra.push_back(_new_item_slot)
	return _cra

func update_items() -> void:
	inventory.sort_custom(sort_slot_id)
	consumables.sort_custom(sort_slot_id)
	crafts.sort_custom(sort_slot_id)
	
	hud.update_inventory()

func sort_slot_id(a : ItemSlot, b : ItemSlot) -> bool:
	return a.slot_id < b.slot_id

func get_slot_taken_count() -> int:
	var _item_count : int = 0
	for i in inventory:
		if i.item:
			_item_count += 1
	return _item_count

func is_inventory_full() -> bool:
	return false if get_empty_slot(inventory) else true

func get_empty_slot(item_source : Array[ItemSlot]) -> ItemSlot:
	for i in item_source:
		if !i.item:
			return i
	return null

func has_item(itm : Item, item_source : Array[ItemSlot]) -> bool:
	for i in item_source:
		if i.item == itm:
			return true
	return false

func get_item_slot(itm : Item, item_source : Array[ItemSlot]) -> ItemSlot:
	for i in item_source:
		if i.item == itm:
			return i
	return null

# Only works with inventory
func obtain_item(item : Item, quantity : int = 1) -> void:
	if has_item(item, get_item_source(item)):
		get_item_slot(item, get_item_source(item)).quantity += quantity
	else:
		if get_slot_taken_count() >= INVENTORY_SIZE:
			var _item_slot = ItemSlot.new()
			_item_slot.item = item
			_item_slot.quantity = quantity
			drop_item_ground(_item_slot)
			return
		var _empty_slot = get_empty_slot(get_item_source(item))
		_empty_slot.item = item
		_empty_slot.quantity = quantity
	update_items()
	update_stats()
	hud.update_abilities()
	
	for ab in item.abilities:
		hud.bind_ability_to_empty_slot(ab)

func lose_item(item : Item, quantity : int) -> void:
	var _item_slot : ItemSlot = get_item_slot(item, get_item_source(item))
	_item_slot.quantity -= quantity
	if _item_slot.quantity <= 0:
		_item_slot.quantity = 0
		_item_slot.item = null
	
	update_items()
	update_stats()
	hud.update_abilities()

func get_item_source(item : Item) -> Array[ItemSlot]:
	return consumables if item.type == Basics.ItemType.CONSUMABLE else inventory

func get_item_slot_source(item_slot : ItemSlot) -> Array[ItemSlot]:
	return consumables if item_slot.slot_type == Basics.SlotType.CONSUMABLE else inventory

func craft_item() -> void:
	if not crafts[0].item or not crafts[1].item:
		return
 
	var item_a : Item = crafts[0].item
	var item_b : Item = crafts[1].item
 
	# Find which item in the game data can be crafted from these two
	var result_item : Item = null
	for candidate in world.resources.all_items:
		if candidate.is_craftable_from(item_a, item_b):
			result_item = candidate.duplicate()
			break
 
	if not result_item:
		# No valid craft — clear inputs, drop nothing
		for i in range(2):
			crafts[i].item     = null
			crafts[i].quantity = 0
		hud.update_craft()
		return
 
	# Transfer stats from the second input into the result
	# This may trigger an evolution
	var evolved : Item = result_item.combine_stats_from(item_b)
	if evolved:
		result_item = evolved
 
	# Place result in slot 2 (the preview/output slot)
	crafts[0].item     = null
	crafts[0].quantity = 0
	crafts[1].item     = null
	crafts[1].quantity = 0
	crafts[2].item     = result_item
	crafts[2].quantity = 1
 
	hud.update_craft()

# Used to clear the craft tab when exiting the base
func clear_craft() -> void:
	for i in range(crafts.size()):
		if crafts[i].item:
			obtain_item(crafts[i].item, crafts[i].quantity)
			crafts[i].item = null
			crafts[i].quantity = 0
	hud.update_craft()

func entering_base() -> void:
	area_health_regeneration = SPAWN_REGEN
	update_stats()
	in_base = true
	hud.update_craft()

func exit_base() -> void:
	area_health_regeneration = 0
	update_stats()
	in_base = false
	clear_craft()

## Flat bonus added per level above 1, keyed by stat ID.
## Rythic grows separately through items and level curve (TBD).
const LEVEL_BONUSES : Dictionary = {
	Entity.S_MAX_HEALTH     : 50,
	Entity.S_PHYSICAL       : 3,
	Entity.S_TENSION        : 3,
	Entity.S_WITHERING      : 3,
	Entity.S_MOVEMENT_SPEED : 1,
}

func update_stats() -> void:
	# 1. Reset all computed stats to base values
	entity.reset_stats()

	# 2. Apply level scaling bonuses
	for stat_id in LEVEL_BONUSES:
		entity.add_stat(stat_id, (level - 1) * LEVEL_BONUSES[stat_id])

	# 3. Apply area regeneration bonus (e.g. being in base)
	entity.add_stat(Entity.S_HEALTH_REGEN, area_health_regeneration)

	# 4. Apply all inventory item stats in a single generic loop
	for slot in inventory:
		if not slot.item:
			continue
		for stat_id in slot.item.stats:
			entity.add_stat(stat_id, slot.item.stats[stat_id])

	# 5. Clamp health to new max in case max_health was reduced
	entity.health = min(entity.health, entity.get_max_health())

	# 6. Notify listeners
	entity.state_changed.emit()
	hud.update_stats_hud()

func is_item_craftable(item : Item, comps : Array[Item]) -> bool:
	var recipe = [item.craft_1, item.craft_2]
	return (comps[0] == recipe[0] and comps[1] == recipe[1]) or (comps[0] == recipe[1] and comps[1] == recipe[0])

func _on_nav_path_changed() -> void:
	hud.mini_map.update_movement_line(nav)

func _on_update_movement_line_timeout():
	if nav.target_position == Vector3(0.0, 0.0, 0.0):
		nav.target_position = global_position
	nav.target_position = nav.target_position + Vector3(0.0001, 0.0, -0.0001)

func _on_stat_regen_timeout():
	heal(int(entity.get_health_regen()))
