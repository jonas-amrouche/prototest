extends Node3D

@onready var manager = get_node("..")

var pre_beacon = preload("res://Scenes/Props/VisionBeacon.tscn")
var vision_stone = preload("res://Ressources/Components/VisionStone.tres")

var ward_position : Vector3

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead() and manager.player.components.has(vision_stone):
			manager.look_at_cursor(ability_dealer)
			manager.player.lose_component(vision_stone, 1)
			manager.in_animation = true
			ward_position = manager.get_cursor_world_position(ability_dealer)
			ward_position = (ward_position-manager.player.position).limit_length(5.0) + manager.player.position
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				manager.in_animation = false
				var _new_beacon = pre_beacon.instantiate()
				_new_beacon.position = Vector3(ward_position.x, -0.4, ward_position.z)
				manager.player.world.beacons.add_child(_new_beacon)
				manager.start_ability_cooldown(ability)
				queue_free()))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.UNAVAILABLE
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN
