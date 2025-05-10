extends Node3D

var ad : AbilityData

@onready var manager = get_node("..")

var red_liquor = preload("res://Resources/Effects/red_liquor.tres")

func press() -> Basics.AbilityError:
	ad.ability_dealer.add_effect(red_liquor, ad.ability_dealer)
	manager.start_ability_cooldown(ad.ability)
	return Basics.AbilityError.OK
