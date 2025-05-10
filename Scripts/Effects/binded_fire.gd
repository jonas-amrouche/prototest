extends Node3D

var effect : Effect

var effect_dealer : Object
var effect_victim : Object

@onready var manager = get_node("..")

func _on_tick_timeout() -> void:
	effect_victim.heal(effect.custom_data[0])
