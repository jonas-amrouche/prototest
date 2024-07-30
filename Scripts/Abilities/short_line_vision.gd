extends Node3D

@onready var manager = get_node("..")
@onready var fog = $FogVolume

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			manager.look_at_cursor(ability_dealer)
			top_level = true
			manager.in_animation = true
			manager.block_player_position(ability_dealer)
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				manager.in_animation = false
				fog.show()
				manager.unblock_player_position(ability_dealer)
				manager.start_ability_cooldown(ability)
				get_tree().create_timer(2.0).timeout.connect(Callable(func():
					queue_free()))))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.UNAVAILABLE
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN
