extends Node3D

@onready var collision = $Area
@onready var manager = get_node("..")

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			manager.in_animation = true
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				for p in collision.get_overlapping_bodies():
					if p != ability_dealer and !ability_dealer.is_dead():
						p.take_damage(ability_dealer.stats.magic_damage, 1, ability_dealer)
				manager.in_animation = false
				manager.start_ability_cooldown(ability)
				queue_free()))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.DEAD
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN
