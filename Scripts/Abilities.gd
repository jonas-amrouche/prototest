extends Node3D

var active_abilities : Dictionary  # Contains ability in keys and scene ability ref in values
var cooldown_dict : Dictionary # Contains ability in keys and cooldowns timer refs in values
var in_cooldown_dict : Dictionary # Contains ability in keys and in_cooldown boolean in values

var in_casting : bool

@onready var entity = get_node("..") # It can either be a player or a monster

func use_ability(ability : Ability, ability_dealer : Object) -> Basics.AbilityError:
	if !in_casting and !in_cooldown_dict.get(ability):
		if !ability_dealer.is_dead():
			if !ability.targeted or get_target(ability):
				if !ability.targeted or is_in_range(ability):
					var _ability_data = AbilityData.new()
					_ability_data.ability = ability
					_ability_data.ability_dealer = ability_dealer
					_ability_data.is_auto_attack = ability.slot_id == 10
					var _path = "res://Scenes/Abilities/" + ability.id + ".tscn"
					if !ResourceLoader.exists(_path):
						push_warning("RESOURCE ABILITY DON'T EXIST")
						return Basics.AbilityError.SCRIPT_ERROR
					var _new_ability = load("res://Scenes/Abilities/" + ability.id + ".tscn").instantiate()
					_new_ability.rotation = Vector3()
					_new_ability.ad = _ability_data
					add_child(_new_ability)
					active_abilities[ability] = _new_ability
					_new_ability.connect("tree_exiting", Callable(self, "destroy_ability").bind(ability))
					
					start_ability_life_time(_new_ability)
					return _new_ability.call("press")
				else:
					return Basics.AbilityError.NO_TARGET
			else:
				return Basics.AbilityError.OUT_OF_RANGE
		else:
			return Basics.AbilityError.UNAVAILABLE
	return Basics.AbilityError.IN_COOLDOWN

func start_ability_life_time(ability_scene : Object) -> void:
	var _life_time = ability_scene.ad.ability.life_time
	if _life_time == 0.0:
		return
	get_tree().create_timer(_life_time).timeout.connect(func():
		if ability_scene:
			ability_scene.queue_free())

func release_ability(ability : Ability) -> Basics.AbilityError:
	if active_abilities.has(ability) and active_abilities.get(ability).has_method("release"):
		return active_abilities.get(ability).call("release")
	return Basics.AbilityError.UNAVAILABLE

# Clear the ability from the dictionnary
func destroy_ability(ability : Ability) -> void:
	active_abilities.erase(ability)

# Tell all active abilities, there can be a cancelling with a reason
func cancel_abilities(reason : Basics.AbilityCancel) -> void:
	for a in active_abilities.values():
		if a.has_method("cancel_ability"):
			a.cancel_ability(reason)

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

var channeling_tween
func start_channeling(duration : float, title : String, inverse : bool = false) -> void:
	entity.hud.channeling_label.text = title
	entity.hud.channeling_bar.set_visible(true)
	if channeling_tween:
		channeling_tween.kill()
	channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	if inverse:
		channeling_tween.tween_method(Callable(entity.hud.channeling_bar, "set_value"), 100.0, 0.0, duration)
	else:
		channeling_tween.tween_method(Callable(entity.hud.channeling_bar, "set_value"), 0.0, 100.0, duration)
	channeling_tween.finished.connect(func():
		stop_channeling())

func stop_channeling() -> void:
	entity.hud.channeling_bar.set_visible(false)

func get_ability_cooldown(ability : Ability):
	if cooldown_dict.get(ability) and cooldown_dict.get(ability).time_left == 0.0:
		return null
	elif cooldown_dict.get(ability):
		return cooldown_dict.get(ability).time_left
	else:
		return null

func get_targeted_ability_range(ability_id : String) -> float:
	var ab = load("res://Scenes/Abilities/" + ability_id + ".tscn").instantiate()
	
	if ab.has_node("Area/Col") and ab.get_node("Area/Col").shape.is_class("CylinderShape3D"):
		ab.queue_free()
		return ab.get_node("Area/Col").shape.get("radius")
	return -1.0

func is_in_range(ab : Ability) -> bool:
	var _entity_pos = Vector2(entity.global_position.x, entity.global_position.z)
	var _target_pos = Vector2(get_target(ab).global_position.x, get_target(ab).global_position.z)
	return _entity_pos.distance_to(_target_pos) < (ab.spell_range if ab.spell_range > 0 else 100000.0)

#func get_ability_range(ability_id : String) -> float:
	#var ab = load("res://Scenes/Abilities/" + ability_id + ".tscn").instantiate()
	#if ab.get_node("Area/Col").shape.is_class("CylinderShape3D"):
		#ab.queue_free()
		#return ab.get_node("Area/Col").shape.get("radius")
	#else:
		##print(ab.get_node("Area/Col").shape.get("size").z/2.0 + ab.get_node("Area/Col").position.z)
		#ab.queue_free()
		#return ab.get_node("Area/Col").shape.get("size").z/2.0 + ab.get_node("Area/Col").position.z

func has_active_abilities() -> bool:
	return active_abilities.size() > 0

const RAY_LENGTH := 100.0
func terrain_raycast() -> Dictionary:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _ray_query = PhysicsRayQueryParameters3D.new()
		_ray_query.from = entity.camera.project_ray_origin(_mouse_pos)
		_ray_query.to = _ray_query.from + entity.camera.project_ray_normal(_mouse_pos) * RAY_LENGTH
		_ray_query.collision_mask = 1
		return get_world_3d().direct_space_state.intersect_ray(_ray_query)

func look_at_target(ab : Ability) -> void:
	if ab.slot_id == 10 or ab.targeted:
		var _target = get_target(ab)
		if _target:
			look_at(Vector3(_target.global_position.x, global_position.y, _target.global_position.z))
	else:
		var _result = terrain_raycast()
		if !_result.is_empty():
			look_at(Vector3(_result.get("position").x, global_position.y, _result.get("position").z))

func get_damage(ad : AbilityData) -> Dictionary:
	var _dict = Dictionary()
	_dict["damage_type"] = ad.ability.damage_type
	
	var _damage : int
	if ad.ability.damage_type == Basics.DamageType.PHYSIC:
		_damage = ad.ability_dealer.entity.physical_damage
	else:
		_damage = ad.ability_dealer.entity.magic_damage
	
	# If monster, don't care about damage cap
	if ad.ability_dealer.entity.entity_type == Basics.EntityType.MONSTER:
		_dict["damage"] = _damage
	else:
		_dict["damage"] = min(_damage, ad.ability.damage_cap)
	
	return _dict

func get_target(ab : Ability) -> Object:
	if ab.slot_id == 10 or ab.slot_id == -1: # Second condition identify monsters
		return entity.auto_attack_target
	else:
		return entity.hovered_target

func get_cursor_world_position() -> Vector3:
	var _result = terrain_raycast()
	if !_result.is_empty():
		return _result.get("position")
	return Vector3()

func stop_player_path(ability_dealer : Object) -> void:
	ability_dealer.nav.target_position = global_position

func disable_player_movement(ability_dealer : Object) -> void:
	ability_dealer.can_move = false

func enable_player_movement(ability_dealer : Object) -> void:
	ability_dealer.can_move = true
