extends Node3D

var ad : AbilityData

@onready var manager = get_node("..")

func press() -> Basics.AbilityError:
	manager.in_casting = true
	ad.ability_dealer.update_path(true)
	ad.ability_dealer.update_path_timer.stop()
	var _target = manager.get_target(ad.ability)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		var _damage = manager.get_damage(ad)
		_target.take_damage(_damage.damage, _damage.damage_type, ad.ability_dealer)
		manager.in_casting = false
		ad.ability_dealer.update_path()
		ad.ability_dealer.update_path_timer.start()
		manager.start_ability_cooldown(ad.ability))
	return Basics.AbilityError.OK
