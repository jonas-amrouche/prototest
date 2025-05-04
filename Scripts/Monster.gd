extends CharacterBody3D

var entity_type = Basics.EntityType.MONSTER
var monster : Monster

var monster_model : Object

@onready var stats := {"physical_damage" : monster.physical_damage, \
"magic_damage" : monster.magic_damage, \
"physical_armor" : monster.physical_armor, \
"magic_armor" : monster.magic_armor, \
"movement_speed" : monster.movement_speed, \
"health_regeneration" : monster.health_regeneration, \
"max_health" : monster.max_health}

@onready var health : int = monster.max_health
var level := int(1)
var auto_attack_target : Object

const ROTATION_LERP_SPEED := 0.04
var target_direction := Vector3()
var default_point := Vector3()
var in_attack_range : bool

var roam_point : Vector3

var loot : Array[ItemSlot]

var camp  : Object
@onready var nav = $NavAgent
@onready var ability_machine = $Abilities
@onready var effect_machine = $Effects
@onready var agro_collision = $Aggro/Collision
@onready var monster_collision = $Collision
@onready var health_bar = $SubViewport/MonsterHealthBar/HealthBar
@onready var level_label = $SubViewport/MonsterHealthBar/LevelLabel
@onready var health_bar_display = $HealthBarDisplay
@onready var update_path_timer = $UpdatePath
@onready var attack_timer = $Attack
@onready var roam_timer = $Roam
@onready var looting_particles = $LootingStars
@onready var world = get_node("..").get_node("..")

signal state_changed

func _ready():
	if monster.roam:
		roam_timer.start()
		update_path_timer.start()
	agro_collision.shape.set("radius", monster.aggro_range)
	default_point = global_position
	for i in range(level-1):
		stats.magic_damage *= 1.5
		stats.physical_damage *= 1.5
		stats.magic_armor *= 1.2
		stats.physical_armor *= 1.2
		stats.max_health *= 1.5
		stats.health_regeneration *= 1.5
		stats.movement_speed *= 1.05
	health = stats.max_health
	level_label.text = str(level)
	monster_model = monster.monster_model.instantiate()
	for c in monster_model.get_children():
		if c.is_class("MeshInstance3D"):
			c.layers = 3
	add_child(monster_model)
	monster_model.rotation.y = randf() * PI * 2.0
	target_direction = global_transform.basis.x

func add_effect(effect : Effect, effect_dealer : Object) -> void:
	effect_machine.spawn_effect(effect, effect_dealer)
	if effect.duration > 0.0:
		get_tree().create_timer(effect.duration).timeout.connect(remove_effect.bind(effect))

func remove_effect(effect : Effect) -> void:
	effect_machine.destroy_effect(effect)

func hover_target() -> void:
	for c in monster_model.get_children():
		if c.is_class("MeshInstance3D"):
			c.set_layer_mask_value(14, true)

func stop_hovering_target() -> void:
	for c in monster_model.get_children():
		if c.is_class("MeshInstance3D"):
			c.set_layer_mask_value(14, false)

func select_target() -> void:
	for c in monster_model.get_children():
		if c.is_class("MeshInstance3D"):
			c.set_layer_mask_value(14, false)
			c.set_layer_mask_value(15, true)

func lose_target() -> void:
	for c in monster_model.get_children():
		if c.is_class("MeshInstance3D"):
			c.set_layer_mask_value(15, false)

func take_damage(damage : int, damage_type, damage_dealer : Object) -> void:
	if is_dead():
		return
	if !auto_attack_target:
		update_path_timer.start()
		update_path()
		attack_timer.start()
	auto_attack_target = damage_dealer
	
	health_bar_display.show()
	
	var _final_damage : int
	match damage_type:
		0:
			_final_damage = max(damage - damage * min(0.99, stats.physical_armor / damage), 0.0)
		1:
			_final_damage = max(damage - damage * min(0.99, stats.magic_armor / damage), 0.0)
	
	if damage_dealer.has_passive("jungle_way"):
		_final_damage += 5
	
	health = max(health - _final_damage, 0.0)
	health_bar.value = float(health) / float(stats.max_health) * 100.0
	state_changed.emit()
	if is_dead():
		damage_dealer.gain_experience(monster.experience_drop)
		die()

func is_dead() -> bool:
	if health == 0:
		return true
	return false

func gain_experience(_experience : float) -> void:
	print("monster gained experience")
	return

const DROP_VECTOR_LENGTH = 1.2
func die() -> void:
	generate_loot()
	rotation.x = PI/2.0
	looting_particles.emitting = true
	health_bar_display.hide()
	set_physics_process(false)
	camp.monster_died()

func generate_loot() -> void:
	randomize()
	for id in monster.item_drops:
		var _new_item_slot = ItemSlot.new()
		_new_item_slot.item = id.item
		_new_item_slot.quantity = 0
		for q in id.quantity_max:
			if randf() < id.chances:
				_new_item_slot.quantity += 1
		if _new_item_slot.quantity > 0:
			loot.append(_new_item_slot)

func loot_body() -> void:
	monster_collision.disabled = true
	var _dissapear_tween = get_tree().create_tween()
	_dissapear_tween.tween_property(self, "position", position + Vector3(0, -1.0, 0),0.5)
	_dissapear_tween.finished.connect(func():
		queue_free())

func _physics_process(_delta) -> void:
	update_direction()
	movement()

func kill_player() -> void:
	print("slay by monster you noob")

func face_direction(direction : Vector3) -> void:
	target_direction = lerp(target_direction, direction, ROTATION_LERP_SPEED)

func update_direction() -> void:
	var _vec_look = -target_direction + Vector3(global_position.x, monster_model.global_position.y, global_position.z)
	if _vec_look.is_equal_approx(monster_model.global_position):
		return
	ability_machine.look_at(_vec_look)
	monster_model.look_at(_vec_look)

func movement() -> void:
	var input_dir = Vector2()
	if !nav.is_navigation_finished():
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	var direction = Vector3(input_dir.x, 0, input_dir.y).normalized()
	if direction:
		velocity.x = direction.x * stats.movement_speed
		velocity.z = direction.z * stats.movement_speed
		face_direction(direction.rotated(Vector3.UP, PI/2.0))
	else:
		if auto_attack_target:
			face_direction(global_position.direction_to(Vector3(auto_attack_target.global_position.x, global_position.y, auto_attack_target.global_position.z)).rotated(Vector3.UP, PI/2.0))
		velocity.x = move_toward(velocity.x, 0, stats.movement_speed)
		velocity.z = move_toward(velocity.z, 0, stats.movement_speed)
	
	move_and_slide()

func _on_update_path_timeout():
	update_path()

const STOP_DISTANCE_PLAYER := 1.2
const STOP_DISTANCE_CAMP := 0.7
const STOP_DISTANCE_ROAM_POINT := 0.7
func update_path(stop : bool = false) -> void:
	if stop:
		nav.target_position = global_position
	if auto_attack_target:
		nav.path_desired_distance = STOP_DISTANCE_PLAYER
		nav.target_position = auto_attack_target.global_position
	elif monster.roam:
		nav.path_desired_distance = STOP_DISTANCE_ROAM_POINT
		nav.target_position = Vector3(camp.global_position.x, global_position.y, camp.global_position.z) + roam_point
	else:
		nav.path_desired_distance = STOP_DISTANCE_CAMP
		health_bar_display.hide()
		nav.target_position = default_point

func _on_aggro_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if monster.aggro:
		auto_attack_target = body
		update_path_timer.start()
		update_path()
		attack_timer.start()

func _on_aggro_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index):
	auto_attack_target = null
	if !monster.roam:
		update_path_timer.stop()
		update_path()
	attack_timer.stop()

func _on_attack_timeout():
	if auto_attack_target:
		for i in monster.abilities:
			if ability_machine.is_in_range(i):
				ability_machine.use_ability(i, self)

func _on_roam_timeout():
	roam_point = Vector3(randf_range(-monster.roam_range, monster.roam_range), 0.0, randf_range(-monster.roam_range, monster.roam_range))
