extends Node3D

var active_abilities : Dictionary  # Contains ability in keys and scene ability ref in values
var cooldown_dict : Dictionary # Contains ability in keys and cooldowns timer refs in values
var in_cooldown_dict : Dictionary # Contains ability in keys and in_cooldown boolean in values

var in_animation : bool

@onready var entity = get_node("..") # It can either be a player or a monster

func use_ability(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	var _new_ability = load("res://Scenes/Abilities/" + ability.id + ".tscn").instantiate()
	add_child(_new_ability)
	_new_ability.rotation = Vector3()
	active_abilities[ability] = _new_ability
	_new_ability.connect("tree_exiting", Callable(self, "destroy_ability").bind(ability))
	return _new_ability.call("press", ability, ability_dealer)

func release_ability(ability : Ability, ability_dealer : Object) -> Basics.ABILITY_ERROR:
	if active_abilities.has(ability) and active_abilities.get(ability).has_method("release"):
		return active_abilities.get(ability).call("release", ability, ability_dealer)
	return Basics.ABILITY_ERROR.UNAVAILABLE

func destroy_ability(ability : Ability) -> void:
	active_abilities.erase(ability)

func start_ability_cooldown(ability : Ability) -> void:
	in_cooldown_dict[ability] = true
	if entity.is_in_group("player"):
		for a in entity.hud.ability_list.get_children():
			if a.ability == ability:
				a.start_cooldown()
				break
	
	var _timer = get_tree().create_timer(ability.cooldown, false, true)
	_timer.timeout.connect(Callable(func():
		in_cooldown_dict[ability] = false
		cooldown_dict.erase(ability)))
	cooldown_dict[ability] = _timer

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
	var _result = ability_dealer.terrain_raycast()
	if !_result.is_empty():
		look_at(Vector3(_result.get("position").x, global_position.y, _result.get("position").z))

func get_cursor_world_position(ability_dealer : Object) -> Vector3:
	var _result = ability_dealer.terrain_raycast()
	if !_result.is_empty():
		return _result.get("position")
	return Vector3()

func block_player_position(ability_dealer : Object) -> void:
	ability_dealer.can_move = false

func unblock_player_position(ability_dealer : Object) -> void:
	ability_dealer.can_move = true
