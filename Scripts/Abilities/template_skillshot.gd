extends Node3D

var ad : AbilityData

@onready var visual = $Visual
@onready var collision = $Area
@onready var manager = get_node("..")

func press() -> Basics.AbilityError:
	manager.look_at_target(ad.ability)
	manager.in_casting = true
	manager.disable_player_movement(ad.ability_dealer)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		var dmg : Dictionary = manager._compute_damage(ad.ability, ad.ability_dealer)
		for p in collision.get_overlapping_bodies():
			if p != ad.ability_dealer:
				p.take_damage(dmg.amount, dmg.type, ad.ability_dealer)
		manager.in_casting = false
		manager.enable_player_movement(ad.ability_dealer)
		manager.start_ability_cooldown(ad.ability))
	return Basics.AbilityError.OK

func cancel_ability(_reason : Basics.AbilityCancel) -> void:
	pass
