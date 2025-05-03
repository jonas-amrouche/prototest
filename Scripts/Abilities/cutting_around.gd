extends Node3D

var ad : AbilityData

@onready var manager = get_node("..")

func press() -> Basics.ABILITY_ERROR:
	manager.look_at_target(ad.ability)
	manager.in_casting = true
	var _target = manager.get_target(ad.ability)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		var _damage = manager.get_damage(ad)
		_target.take_damage(_damage.damage, _damage.damage_type, ad.ability_dealer)
		manager.in_casting = false
		manager.start_ability_cooldown(ad.ability))
	return Basics.ABILITY_ERROR.OK
