extends Node3D

@onready var collision = $Area
@onready var manager = get_node("..")
enum ERROR {OK, IN_COOLDOWN}

func press(ability : Ability, ability_dealer : Object) -> ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability) and !ability_dealer.is_dead():
		manager.in_animation = true
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			for p in collision.get_overlapping_bodies():
				if p != ability_dealer and !ability_dealer.is_dead():
					p.take_damage(ability_dealer.stats.physical_damage, 0, ability_dealer)
			manager.in_animation = false
			manager.start_ability_cooldown(ability)
			queue_free()))
		return ERROR.OK
	queue_free()
	return ERROR.IN_COOLDOWN
