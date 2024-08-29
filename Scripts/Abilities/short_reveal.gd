extends Node3D

@onready var manager = get_node("..")

var pre_temp_vision = preload("res://Scenes/Props/TempVision.tscn")
var temp_visions_list : Array[Object]
var in_ability : bool

func press(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if !manager.in_animation and !manager.in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			manager.look_at_cursor()
			in_ability = true
			manager.in_animation = true
			for i in range(get_child_count()):
				var _new_temp_vision = pre_temp_vision.instantiate()
				_new_temp_vision.position = Vector3(get_node(str(i)).global_position.x, 0.0, get_node(str(i)).global_position.z)
				_new_temp_vision.radius = 10.0
				manager.entity.world.temp_vision.add_child(_new_temp_vision)
				temp_visions_list.append(_new_temp_vision)
			get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
				manager.in_animation = false
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

func _process(_delta: float) -> void:
	manager.look_at_cursor()
	update_vision_probe_position()

func update_vision_probe_position() -> void:
	for t in range(temp_visions_list.size()):
		temp_visions_list[t].position = Vector3(get_node(str(t)).global_position.x, 0.0, get_node(str(t)).global_position.z)

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
	
