extends Node3D

var ad : AbilityData

@onready var manager = get_node("..")

var pre_beacon = preload("res://Scenes/Props/vision_trinket.tscn")
var vision_stone = preload("res://Resources/Items/vision_stone.tres")

var ward_position : Vector3

func press() -> Basics.ABILITY_ERROR:
	if manager.entity.has_item(vision_stone, manager.entity.inventory):
		manager.look_at_target(ad.ability)
		manager.entity.lose_item(vision_stone, 1)
		manager.in_casting = true
		ward_position = manager.get_cursor_world_position()
		ward_position = (ward_position-manager.entity.position).limit_length(5.0) + manager.entity.position
		get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
			manager.in_casting = false
			var _new_beacon = pre_beacon.instantiate()
			_new_beacon.position = Vector3(ward_position.x, -0.4, ward_position.z)
			manager.entity.world.beacons.add_child(_new_beacon)
			manager.start_ability_cooldown(ad.ability))
		return Basics.ABILITY_ERROR.OK
	queue_free()
	return Basics.ABILITY_ERROR.NEED_RESOURCE
