extends Node3D

var cooldown_dict = {}
var in_cooldown_dict = {}

var in_animation : bool

func use_ability(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	var _new_ability = load("res://Scenes/Abilities/" + ability.id + ".tscn").instantiate()
	add_child(_new_ability)
	_new_ability.rotation = Vector3()
	return _new_ability.call("press", ability, ability_dealer)

func start_ability_cooldown(ability : Ability) -> void:
	in_cooldown_dict.merge({ability : true}, true)
	var _timer = get_tree().create_timer(ability.cooldown)
	_timer.timeout.connect(Callable(func():
		in_cooldown_dict.merge({ability : false}, true)))
	cooldown_dict.merge({ability : _timer}, true)

func get_ability_cooldown(ability : Ability):
	if cooldown_dict.get(ability) and cooldown_dict.get(ability).time_left == 0.0:
		return null
	elif cooldown_dict.get(ability):
		return cooldown_dict.get(ability).time_left
	else:
		return null

func get_ability_range(ability_id : String) -> float:
	var ab = load("res://Scenes/Abilities/" + ability_id + ".tscn").instantiate()
	if ab.get_node("Area/Col").shape.is_class("CylinderShape3D"):
		ab.queue_free()
		return ab.get_node("Area/Col").shape.get("radius")
	else:
		#print(ab.get_node("Area/Col").shape.get("size").z/2.0 + ab.get_node("Area/Col").position.z)
		ab.queue_free()
		return ab.get_node("Area/Col").shape.get("size").z/2.0 + ab.get_node("Area/Col").position.z

func look_at_cursor(ability_dealer : Object) -> void:
	var _result = ability_dealer.terrain_raycast(1)
	if !_result.is_empty():
		look_at(Vector3(_result.get("position").x, global_position.y, _result.get("position").z))

func block_player_position(ability_dealer : Object) -> void:
	ability_dealer.can_move = false

func unblock_player_position(ability_dealer : Object) -> void:
	ability_dealer.can_move = true
