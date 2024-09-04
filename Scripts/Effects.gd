extends Node3D

var active_effects : Dictionary  # Contains effect in keys and scene effect ref in values

@onready var entity = get_node("..") # It can either be a player or a monster

func spawn_effect(effect : Effect, effect_dealer : Object) -> void:
	var _new_effect = load("res://Scenes/Effects/" + effect.id + ".tscn").instantiate()
	_new_effect.effect_dealer = effect_dealer
	_new_effect.effect_victim = entity
	_new_effect.effect = effect
	add_child(_new_effect)
	active_effects[effect] = _new_effect
	_new_effect.rotation = Vector3()

func destroy_effect(effect : Effect) -> void:
	active_effects[effect].queue_free()
	active_effects.erase(effect)

func block_player_position(effect_victim : Object) -> void:
	effect_victim.can_move = false

func unblock_player_position(effect_victim : Object) -> void:
	effect_victim.can_move = true
