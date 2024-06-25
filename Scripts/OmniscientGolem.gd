extends CharacterBody3D

@onready var nav = $NavAgent
@onready var monster_model = $OmniscientGolemModel
@onready var health_bar = $SubViewport/Infos/HealthBar
@onready var update_path_timer = $UpdatePath
@onready var attack_timer = $AttackTimer
@onready var attack_indicator = $AttackIndicator

var physical_damage := 50.0
var magic_damage := 50.0
var physical_armor := 15.0
var magic_armor := 15.0
var movement_speed : float = 1.5
var health_regeneration := 10.0
var max_health := 1000
var health : int = max_health
var player_target : Object

const ROTATION_LERP_SPEED := 0.04
var target_direction := Vector3()
var default_point := Vector3()
var in_attack_range : bool

func _ready():
	default_point = global_position
	monster_model.rotation.y = randf() * PI * 2.0
	target_direction = global_transform.basis.x

func take_damage(damage : int, damage_dealer : Object) -> void:
	player_target = damage_dealer
	health = clamp(health - damage, 0.0, max_health)
	health_bar.value = float(health) / float(max_health) * 100.0

func _physics_process(_delta) -> void:
	update_direction()
	movement()

func face_direction(direction : Vector3) -> void:
	target_direction = lerp(target_direction, direction, ROTATION_LERP_SPEED)

func update_direction() -> void:
	monster_model.look_at(-target_direction + Vector3(global_position.x, monster_model.global_position.y, global_position.z))

func movement() -> void:
	var input_dir = Vector2()
	if !nav.is_navigation_finished():
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
		face_direction(direction.rotated(Vector3.UP, PI/2.0))
	else:
		if player_target:
			face_direction(global_position.direction_to(Vector3(player_target.global_position.x, global_position.y, player_target.global_position.z)).rotated(Vector3.UP, PI/2.0))
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)
	
	move_and_slide()

func _on_update_path_timeout():
	update_path()

const STOP_DISTANCE_PLAYER := 1.2
const STOP_DISTANCE_CAMP := 0.7
func update_path(stop : bool = false) -> void:
	if stop:
		nav.target_position = global_position
	if player_target:
		nav.path_desired_distance = STOP_DISTANCE_PLAYER
		nav.target_position = player_target.global_position
	else:
		nav.path_desired_distance = STOP_DISTANCE_CAMP
		nav.target_position = default_point

func _on_aggro_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	player_target = body
	update_path_timer.start()
	update_path()

func _on_aggro_body_shape_exited(_body_rid, _body, _body_shape_index, _local_shape_index):
	player_target = null
	update_path_timer.stop()
	update_path()

func start_attack() -> void:
	attack_indicator.set_visible(true)
	update_path_timer.stop()
	update_path(true)
	attack_timer.start()

func hit_player() -> void:
	player_target.take_damage(physical_damage)

func _on_strike_body_entered(_body):
	in_attack_range = true
	if attack_timer.is_stopped():
		start_attack()

func _on_strike_body_exited(_body):
	in_attack_range = false

func _on_attack_timer_timeout():
	attack_indicator.set_visible(false)
	if in_attack_range:
		hit_player()
		start_attack()
	else:
		attack_timer.stop()
	update_path_timer.start()
	update_path()
