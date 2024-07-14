extends Node3D

const GRUNTER = preload("res://Ressources/Monsters/Grunter.tres")

@onready var visual = $Visual
@onready var collision = $Area
@onready var manager = get_node("..")
enum ERROR {OK, IN_COOLDOWN}

func press(ability : Ability, ability_dealer : Object) -> ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability) and !ability_dealer.is_dead():
		visual.set_visible(true)
		manager.in_animation = true
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			visual.set_visible(false)
			for p in collision.get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(GRUNTER.physical_damage, 0, ability_dealer)
			manager.in_animation = false
			manager.start_ability_cooldown(ability)
			queue_free()))
		return ERROR.OK
	queue_free()
	return ERROR.IN_COOLDOWN
