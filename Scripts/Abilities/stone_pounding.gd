extends Node3D

const OMNISCIENT_GOLEM = preload("res://Ressources/Monsters/OmniscientGolem.tres")

@onready var collision = $Area
@onready var manager = get_node("..")

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			ability_dealer.update_path(true)
			ability_dealer.update_path_timer.stop()
			manager.in_animation = true
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				for p in collision.get_overlapping_bodies():
					if p != ability_dealer and !ability_dealer.is_dead():
						p.take_damage(OMNISCIENT_GOLEM.physical_damage, 0, ability_dealer)
				manager.in_animation = false
				ability_dealer.update_path()
				ability_dealer.update_path_timer.start()
				manager.start_ability_cooldown(ability)
				queue_free()))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.DEAD
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN
