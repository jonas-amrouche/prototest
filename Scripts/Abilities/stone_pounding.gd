extends Node3D

var ad : AbilityData

@onready var collision = $Area
@onready var manager = get_node("..")

func press() -> Basics.ABILITY_ERROR:
	ad.ability_dealer.update_path(true)
	ad.ability_dealer.update_path_timer.stop()
	manager.in_casting = true
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		for p in collision.get_overlapping_bodies():
			if p != ad.ability_dealer and !ad.ability_dealer.is_dead():
				p.take_damage(ad.ability_dealer.stats.physical_damage, 0, ad.ability_dealer)
		manager.in_casting = false
		ad.ability_dealer.update_path()
		ad.ability_dealer.update_path_timer.start()
		manager.start_ability_cooldown(ad.ability))
	return Basics.ABILITY_ERROR.OK
