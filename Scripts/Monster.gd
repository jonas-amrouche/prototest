extends CharacterBody3D

var monster : Monster

var monster_model

@onready var stats := {"physical_damage" : monster.physical_damage, \
"magic_damage" : monster.magic_damage, \
"physical_armor" : monster.physical_armor, \
"magic_armor" : monster.magic_armor, \
"movement_speed" : monster.movement_speed, \
"health_regeneration" : monster.health_regeneration, \
"max_health" : monster.max_health}

@onready var health : int = monster.max_health
var level := int(1)
var player_target : Object

const ROTATION_LERP_SPEED := 0.04
var target_direction := Vector3()
var default_point := Vector3()
var in_attack_range : bool

var roam_point : Vector3

@onready var camp = get_node("..")
@onready var nav = $NavAgent
@onready var ability_machine = $Abilities
@onready var effect_machine = $Effects
@onready var agro_collision = $Aggro/Collision
@onready var monster_collision = $Collision
@onready var health_bar = $SubViewport/Infos/HealthBar
@onready var level_label = $SubViewport/Infos/LevelPan/LevelLab
@onready var update_path_timer = $UpdatePath
@onready var attack_timer = $Attack
@onready var roam_timer = $Roam

var pre_component_drop = preload("res://Scenes/ComponentDrop.tscn")

func _ready():
	if monster.roam:
		roam_point = position
		roam_timer.start()
		update_path_timer.start()
	agro_collision.shape.set("radius", monster.aggro_range)
	default_point = global_position
	monster_model = monster.monster_model.instantiate()
	add_child(monster_model)
	monster_model.rotation.y = randf() * PI * 2.0
	level_label.text = str(level)
	target_direction = global_transform.basis.x

func add_effect(effect : Effect, effect_dealer : Object) -> void:
	effect_machine.spawn_effect(effect, effect_dealer)
	if effect.duration > 0.0:
		get_tree().create_timer(effect.duration).timeout.connect(remove_effect.bind(effect))

func remove_effect(effect : Effect) -> void:
	effect_machine.destroy_effect(effect)

func take_damage(damage : int, damage_type, damage_dealer : Object) -> void:
	if !player_target:
		player_target = damage_dealer
		update_path_timer.start()
		update_path()
		attack_timer.start()
	
	var _final_damage : int
	match damage_type:
		0:
			_final_damage = max(damage - stats.physical_armor, 0.0)
		1:
			_final_damage = max(damage - stats.magic_armor, 0.0)
	
	health = max(health - _final_damage, 0.0)
	health_bar.value = float(health) / float(stats.max_health) * 100.0
	if is_dead():
		damage_dealer.gain_experience(monster.experience_drop)
		die()

func is_dead() -> bool:
	if health == 0:
		return true
	return false

func gain_experience(_experience : float) -> void:
	return

const DROP_VECTOR_LENGTH = 1.2
func die() -> void:
	camp.world.remove_entity(self)
	monster_collision.disabled = true
	for i in range(monster.drop_components.size()):
		var _new_component_ground = pre_component_drop.instantiate()
		var _vector_drop = Vector3.FORWARD.rotated(Vector3.UP, randf_range(-PI, PI)) * DROP_VECTOR_LENGTH
		_new_component_ground.position = _vector_drop + position
		_new_component_ground.component = monster.drop_components[i]
		_new_component_ground.quantity = monster.drop_quantities[i]
		get_node("..").add_child(_new_component_ground)
	set_physics_process(false)
	get_node("..").monster_died()
	get_tree().create_timer(1.0).timeout.connect(Callable(func():
		queue_free()))

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
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * stats.movement_speed
		velocity.z = direction.z * stats.movement_speed
		face_direction(direction.rotated(Vector3.UP, PI/2.0))
	else:
		if player_target:
			face_direction(global_position.direction_to(Vector3(player_target.global_position.x, global_position.y, player_target.global_position.z)).rotated(Vector3.UP, PI/2.0))
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
	if player_target:
		nav.path_desired_distance = STOP_DISTANCE_PLAYER
		nav.target_position = player_target.global_position
	elif monster.roam:
		nav.path_desired_distance = STOP_DISTANCE_ROAM_POINT
		nav.target_position = get_node("..").global_position + roam_point
	else:
		nav.path_desired_distance = STOP_DISTANCE_CAMP
		nav.target_position = default_point

func _on_aggro_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	if monster.aggro:
		player_target = body
		update_path_timer.start()
		update_path()
		attack_timer.start()

func _on_aggro_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index):
	player_target = null
	if !monster.roam:
		update_path_timer.stop()
		update_path()
	attack_timer.stop()

func _on_attack_timeout():
	if player_target:
		for i in monster.abilities:
			if ability_machine.get_ability_range(i.id) > player_target.global_position.distance_to(global_position) - player_target.get_node("Collision").shape.get("radius")/2.0:
				ability_machine.use_ability(i, self)

func _on_roam_timeout():
	roam_point = Vector3(randf_range(-monster.roam_range, monster.roam_range), 0.0, randf_range(-monster.roam_range, monster.roam_range))
