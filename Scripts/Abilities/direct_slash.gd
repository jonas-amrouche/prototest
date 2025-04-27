extends Node3D

var ad : AbilityData

@onready var visual = $Visual
@onready var collision = $Area
@onready var manager = get_node("..")

func press() -> Basics.ABILITY_ERROR:
	manager.look_at_target(ad.ability)
	manager.in_casting = true
	manager.disable_player_movement(ad.ability_dealer)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		for p in collision.get_overlapping_bodies():
			if p != ad.ability_dealer:
				p.take_damage(min(ad.ability_dealer.stats.physical_damage, ad.ability.damage_cap), 0, ad.ability_dealer)
		manager.in_casting = false
		manager.enable_player_movement(ad.ability_dealer)
		manager.start_ability_cooldown(ad.ability))
	return Basics.ABILITY_ERROR.OK
