extends CharacterBody3D

@onready var nav = $NavAgent
@onready var monster_model = $OmniscientGolemModel
@onready var health_bar = $SubViewport/Infos/HealthBar

var max_health : int = 1000
var health : int = max_health
var movement_speed : float = 3.0

const ROTATION_LERP_SPEED := 0.2
var target_direction := Vector3()

func _ready():
	nav.target_position = global_position
	rotation.y = randf() * PI * 2.0

func take_damage(damage : int) -> void:
	health = clamp(health - damage, 0.0, max_health)
	health_bar.value = float(health) / float(max_health) * 100.0

func face_direction(direction : Vector3) -> void:
	target_direction = lerp(target_direction, direction, ROTATION_LERP_SPEED)

func update_direction() -> void:
	monster_model.look_at(-target_direction + Vector3(global_position.x, monster_model.global_position.y, global_position.z))

func _physics_process(_delta):
	var input_dir = Vector2()
	if !nav.is_navigation_finished():
		var _direction_result = global_position.direction_to(nav.get_next_path_position())
		input_dir = Vector2(_direction_result.x, _direction_result.z)
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		velocity.x = direction.x * movement_speed
		velocity.z = direction.z * movement_speed
	else:
		velocity.x = move_toward(velocity.x, 0, movement_speed)
		velocity.z = move_toward(velocity.z, 0, movement_speed)

	move_and_slide()
