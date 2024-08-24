extends Node3D

@onready var visual = $Visual
@onready var collision = $Area
@onready var manager = get_node("..")

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			manager.look_at_cursor(ability_dealer)
			manager.in_animation = true
			manager.block_player_position(ability_dealer)
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				for p in collision.get_overlapping_bodies():
					if p != ability_dealer:
						p.take_damage(min(ability_dealer.stats.physical_damage, ability.damage_cap), 0, ability_dealer)
				manager.in_animation = false
				manager.unblock_player_position(ability_dealer)
				manager.start_ability_cooldown(ability)
				queue_free()))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.UNAVAILABLE
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN
