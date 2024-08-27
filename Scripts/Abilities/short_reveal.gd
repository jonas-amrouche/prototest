extends Node3D

@onready var manager = get_node("..")

var pre_temp_vision = preload("res://Scenes/Props/TempVision.tscn")
var temp_visions_list : Array[Object]
var in_ability : bool

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			manager.look_at_cursor(ability_dealer)
			in_ability = true
			top_level = true
			manager.in_animation = true
			manager.block_player_position(ability_dealer)
			for i in range(get_child_count()):
				var _new_temp_vision = pre_temp_vision.instantiate()
				_new_temp_vision.position = Vector3(get_node(str(i)).global_position.x, 0.0, get_node(str(i)).global_position.z)
				_new_temp_vision.radius = 10.0
				manager.player.world.temp_vision.add_child(_new_temp_vision)
				temp_visions_list.append(_new_temp_vision)
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				manager.in_animation = false
				manager.unblock_player_position(ability_dealer)
				manager.start_ability_cooldown(ability)
				for i in temp_visions_list:
					i.queue_free()
				queue_free()))
			return Basics.ABILITY_ERROR.OK
		else:
			queue_free()
			return Basics.ABILITY_ERROR.UNAVAILABLE
	queue_free()
	return Basics.ABILITY_ERROR.IN_COOLDOWN

func release(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if in_ability:
		manager.in_animation = false
		manager.unblock_player_position(ability_dealer)
		manager.start_ability_cooldown(ability)
		for i in temp_visions_list:
			i.queue_free()
		queue_free()
		return Basics.ABILITY_ERROR.OK
	else:
		return Basics.ABILITY_ERROR.UNAVAILABLE
	
