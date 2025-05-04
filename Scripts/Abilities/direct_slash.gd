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
		for p in collision.get_overlapping_bodies():
			if p != ad.ability_dealer:
				var _damage = manager.get_damage(ad)
				p.take_damage(_damage.damage, _damage.damage_type, ad.ability_dealer)
		manager.in_casting = false
		manager.enable_player_movement(ad.ability_dealer)
		manager.start_ability_cooldown(ad.ability))
	return Basics.AbilityError.OK
