extends StaticBody3D

@onready var world = get_parent().get_parent().get_parent()
@onready var entity : Entity = world.resources.outer_wall_entity.duplicate()
@onready var wall_model = $WallChunkModel/WallChunk
@onready var collision = $Collision

func _ready() -> void:
	entity.set_full_health()

func take_damage(damage : int, damage_type : Basics.DamageType, _damage_dealer : Object) -> void:
	if is_dead():
		return
	if damage_type == Basics.DamageType.PHYSICAL:
		entity.set_health(entity.health - damage)
		if is_dead():
			die()

func is_dead() -> bool:
	if entity.health <= 0:
		return true
	return false

func die() -> void:
	collision.disabled = true
	world.navmesh.bake_navigation_mesh()
	queue_free()

func hover_target() -> void:
	wall_model.set_layer_mask_value(14, true)

func stop_hovering_target() -> void:
	wall_model.set_layer_mask_value(14, false)

func select_target() -> void:
	wall_model.set_layer_mask_value(14, false)
	wall_model.set_layer_mask_value(15, true)

func lose_target() -> void:
	wall_model.set_layer_mask_value(15, false)
