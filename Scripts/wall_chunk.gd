extends StaticBody3D

@onready var world = get_parent().get_parent().get_parent()
@onready var entity : Entity = world.resources.outer_wall_entity

func _ready() -> void:
	entity.set_full_health()

func take_damage(damage : int, damage_type : Basics.DamageType, _damage_dealer : Object) -> void:
	if is_dead():
		return
	if damage_type == Basics.DamageType.PHYSIC or damage_type == Basics.DamageType.HYBRID:
		entity.health = max(entity.health - damage, 0.0)
		entity.state_changed.emit()
		if is_dead():
			die()

func is_dead() -> bool:
	if entity.health <= 0:
		return true
	return false

func die() -> void:
	queue_free()
