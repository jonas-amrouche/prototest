extends Node3D

var ad : AbilityData

@onready var manager = get_node("..")

var pre_temp_vision = preload("res://Scenes/Systems/temp_vision.tscn")
var temp_visions_list : Array[Object]
var in_ability : bool

func press() -> Basics.AbilityError:
	manager.look_at_target(ad.ability)
	in_ability = true
	manager.in_casting = true
	for i in range(get_child_count()):
		var _new_temp_vision = pre_temp_vision.instantiate()
		_new_temp_vision.position = Vector3(get_node(str(i)).global_position.x, 0.0, get_node(str(i)).global_position.z)
		_new_temp_vision.radius = 25.0
		manager.entity.world.temp_vision.add_child(_new_temp_vision)
		temp_visions_list.append(_new_temp_vision)
	get_tree().create_timer(ad.ability.action_time).timeout.connect(func():
		manager.in_casting = false
		manager.start_ability_cooldown(ad.ability)
		for i in temp_visions_list:
			i.queue_free()
		queue_free())
	return Basics.AbilityError.OK

func _process(_delta: float) -> void:
	manager.look_at_target(ad.ability)
	update_vision_probe_position()

func update_vision_probe_position() -> void:
	for t in range(temp_visions_list.size()):
		temp_visions_list[t].position = Vector3(get_node(str(t)).global_position.x, 0.0, get_node(str(t)).global_position.z)

func release() -> Basics.AbilityError:
	if in_ability:
		manager.in_casting = false
		manager.start_ability_cooldown(ad.ability)
		manager.stop_channeling()
		for i in temp_visions_list:
			i.queue_free()
		queue_free()
		return Basics.AbilityError.OK
	else:
		return Basics.AbilityError.UNAVAILABLE
	
