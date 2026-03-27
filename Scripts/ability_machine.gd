## AbilityMachine — manages ability execution for any entity (player or monster).
##
## Design:
##   - Ability scenes are preloaded once at startup via preload_ability_scenes().
##   - Each Ability resource declares an ability_type (TARGETED, SKILLSHOT, etc.).
##   - Execution delegates to typed handler methods rather than per-ability scripts.
##   - New abilities = new resource files only. No new scripts required for
##     standard ability types.
##
## For abilities that genuinely need custom logic beyond the standard types,
## a scene with a custom script can still be placed in res://Scenes/Abilities/
## using the ability's id as the filename. The machine checks for these first.

extends Node3D

# ── State ─────────────────────────────────────────────────────────────────────

var active_abilities  : Dictionary  # Ability -> scene node (if any)
var cooldown_timers   : Dictionary  # Ability -> SceneTreeTimer
var in_cooldown       : Dictionary  # Ability -> bool
var in_casting        : bool = false

# ── Scene cache ───────────────────────────────────────────────────────────────
## Populated once by preload_ability_scenes(). Maps ability_id -> PackedScene.

var _scene_cache : Dictionary = {}

@onready var entity = get_parent()

# ── Startup ───────────────────────────────────────────────────────────────────

## Call once after the entity is ready, passing all abilities it will ever use.
## This eliminates all mid-combat load() calls.
func preload_ability_scenes(abilities : Array) -> void:
	for ab in abilities:
		if ab is Ability and not _scene_cache.has(ab.id):
			var path : String = "res://Scenes/Abilities/" + ab.id + ".tscn"
			if ResourceLoader.exists(path):
				_scene_cache[ab.id] = load(path)

# ── Use ───────────────────────────────────────────────────────────────────────

func use_ability(ability : Ability, dealer : Object) -> Basics.AbilityError:
	if in_casting or in_cooldown.get(ability, false):
		return Basics.AbilityError.IN_COOLDOWN
	if dealer.entity.health <= 0:
		return Basics.AbilityError.UNAVAILABLE
	if ability.targeted and not get_target(ability):
		return Basics.AbilityError.NO_TARGET
	if ability.targeted and not is_in_range(ability):
		return Basics.AbilityError.OUT_OF_RANGE

	# If a custom scene exists for this ability, use it
	if _scene_cache.has(ability.id):
		return _execute_custom(ability, dealer)

	# Otherwise dispatch to the typed handler
	match ability.ability_type:
		Basics.AbilityType.TARGETED:
			return _execute_targeted(ability, dealer)
		Basics.AbilityType.SKILLSHOT:
			return _execute_skillshot(ability, dealer)
		Basics.AbilityType.AREA:
			return _execute_area(ability, dealer)
		Basics.AbilityType.TOGGLE:
			return _execute_toggle(ability, dealer)
		_:
			return Basics.AbilityError.SCRIPT_ERROR

# ── Handlers ──────────────────────────────────────────────────────────────────

func _execute_targeted(ability : Ability, dealer : Object) -> Basics.AbilityError:
	var target := get_target(ability)
	look_at_target(ability)
	in_casting = true
	if ability.channeling:
		start_channeling(ability.action_time, ability.display_name)
	get_tree().create_timer(ability.action_time).timeout.connect(func():
		if target and target.entity.is_alive():
			var dmg := _compute_damage(ability, dealer)
			target.take_damage(dmg.amount, dmg.type, dealer)
			_apply_on_hit_effects(ability, target, dealer)
		in_casting = false
		start_ability_cooldown(ability)
	)
	return Basics.AbilityError.OK

func _execute_skillshot(ability : Ability, dealer : Object) -> Basics.AbilityError:
	look_at_cursor()
	in_casting = true
	if ability.channeling:
		start_channeling(ability.action_time, ability.display_name)
	# Spawn a projectile node that travels forward
	# The projectile handles its own collision and damage on hit
	var proj_scene : PackedScene = _scene_cache.get(ability.id + "_projectile")
	if proj_scene:
		var proj := proj_scene.instantiate()
		proj.setup(ability, dealer)
		get_tree().current_scene.add_child(proj)
	get_tree().create_timer(ability.action_time).timeout.connect(func():
		in_casting = false
		start_ability_cooldown(ability)
	)
	return Basics.AbilityError.OK

func _execute_area(ability : Ability, dealer : Object) -> Basics.AbilityError:
	in_casting = true
	if ability.channeling:
		start_channeling(ability.action_time, ability.display_name)
	get_tree().create_timer(ability.action_time).timeout.connect(func():
		var dmg := _compute_damage(ability, dealer)
		for body in _get_bodies_in_radius(ability.area_radius):
			if body != dealer:
				body.take_damage(dmg.amount, dmg.type, dealer)
				_apply_on_hit_effects(ability, body, dealer)
		in_casting = false
		start_ability_cooldown(ability)
	)
	return Basics.AbilityError.OK

func _execute_toggle(ability : Ability, _dealer : Object) -> Basics.AbilityError:
	# Toggle state is tracked in active_abilities: present = on, absent = off
	if active_abilities.has(ability):
		active_abilities.erase(ability)
	else:
		active_abilities[ability] = true
		start_ability_cooldown(ability)
	return Basics.AbilityError.OK

func _execute_custom(ability : Ability, dealer : Object) -> Basics.AbilityError:
	var scene : PackedScene = _scene_cache[ability.id]
	var node := scene.instantiate()
	node.rotation = Vector3.ZERO
	var ad := AbilityData.new()
	ad.ability        = ability
	ad.ability_dealer = dealer
	ad.is_auto_attack = (ability.slot_id == 10)
	node.ad = ad
	add_child(node)
	active_abilities[ability] = node
	node.connect("tree_exiting", func(): active_abilities.erase(ability))
	_start_lifetime_timer(node, ability.life_time)
	return node.call("press")

# ── Release / cancel ──────────────────────────────────────────────────────────

func release_ability(ability : Ability) -> Basics.AbilityError:
	if active_abilities.has(ability):
		var node = active_abilities[ability]
		if node is Node and node.has_method("release"):
			return node.call("release")
	return Basics.AbilityError.UNAVAILABLE

func cancel_abilities(reason : Basics.AbilityCancel) -> void:
	for node in active_abilities.values():
		if node is Node and node.has_method("cancel_ability"):
			node.cancel_ability(reason)

# ── Cooldown ──────────────────────────────────────────────────────────────────

func start_ability_cooldown(ability : Ability) -> void:
	in_cooldown[ability] = true
	_notify_hud_cooldown_start(ability)
	var timer := get_tree().create_timer(ability.cooldown, false, true)
	timer.timeout.connect(func():
		in_cooldown[ability] = false
		cooldown_timers.erase(ability)
	)
	cooldown_timers[ability] = timer

func get_ability_cooldown_remaining(ability : Ability) -> float:
	var timer = cooldown_timers.get(ability)
	if timer:
		return timer.time_left
	return 0.0

# ── Channeling bar ────────────────────────────────────────────────────────────

var _channeling_tween : Tween

func start_channeling(duration : float, title : String, inverse : bool = false) -> void:
	if not entity.is_in_group("player"):
		return
	entity.hud.channeling_label.text = title
	entity.hud.channeling_bar.show()
	if _channeling_tween:
		_channeling_tween.kill()
	_channeling_tween = get_tree().create_tween().set_trans(Tween.TRANS_LINEAR)
	var from := 100.0 if inverse else 0.0
	var to   := 0.0   if inverse else 100.0
	_channeling_tween.tween_method(
		Callable(entity.hud.channeling_bar, "set_value"), from, to, duration
	)
	_channeling_tween.finished.connect(stop_channeling)

func stop_channeling() -> void:
	if not entity.is_in_group("player"):
		return
	entity.hud.channeling_bar.hide()

# ── Damage calculation ────────────────────────────────────────────────────────

func _compute_damage(ability : Ability, dealer : Object) -> Dictionary:
	var base : int
	match ability.damage_type:
		Basics.DamageType.PHYSICAL:
			base = dealer.entity.get_physical()
		Basics.DamageType.TENSION:
			base = dealer.entity.get_tension()
		Basics.DamageType.WITHERING:
			base = dealer.entity.get_withering()
		_:
			base = 0

	# Apply Rythic scaling based on action time
	var rythic_bonus := int(dealer.entity.get_rythic() * ability.action_time * Basics.RYTHIC_RATE)
	base += rythic_bonus

	var scaled := int(base * ability.damage_scale)
	var amount : int = scaled if ability.damage_cap == 0 else min(scaled, ability.damage_cap)
	return { "amount": amount, "type": ability.damage_type }

# ── Effects on hit ────────────────────────────────────────────────────────────

func _apply_on_hit_effects(ability : Ability, target : Object, dealer : Object) -> void:
	for effect in ability.on_hit_effects:
		if target.has_method("add_effect"):
			target.add_effect(effect, dealer)

# ── Targeting helpers ─────────────────────────────────────────────────────────

func get_target(ab : Ability) -> Object:
	if ab.slot_id == 10 or ab.slot_id == -1:
		return entity.auto_attack_target
	return entity.hovered_target

func is_in_range(ab : Ability) -> bool:
	var target := get_target(ab)
	if not target:
		return false
	if ab.spell_range <= 0.0:
		return true
	var self_pos   := Vector2(entity.global_position.x, entity.global_position.z)
	var target_pos := Vector2(target.global_position.x, target.global_position.z)
	return self_pos.distance_to(target_pos) <= ab.spell_range

func has_active_abilities() -> bool:
	return active_abilities.size() > 0

# ── Raycasts ──────────────────────────────────────────────────────────────────

const RAY_LENGTH := 100.0

func terrain_raycast() -> Dictionary:
	var mouse_pos  := get_viewport().get_mouse_position()
	var ray        := PhysicsRayQueryParameters3D.new()
	ray.from       = entity.camera.project_ray_origin(mouse_pos)
	ray.to         = ray.from + entity.camera.project_ray_normal(mouse_pos) * RAY_LENGTH
	ray.collision_mask = 1
	return get_world_3d().direct_space_state.intersect_ray(ray)

func get_cursor_world_position() -> Vector3:
	var result := terrain_raycast()
	return result.get("position", Vector3.ZERO)

func look_at_target(ability : Ability) -> void:
	var target := get_target(ability)
	if target:
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z))

func look_at_cursor() -> void:
	var result := terrain_raycast()
	if not result.is_empty():
		look_at(Vector3(result["position"].x, global_position.y, result["position"].z))

# ── Utility ───────────────────────────────────────────────────────────────────

func stop_player_path(dealer : Object) -> void:
	dealer.nav.target_position = dealer.global_position

func disable_player_movement(dealer : Object) -> void:
	dealer.can_move = false

func enable_player_movement(dealer : Object) -> void:
	dealer.can_move = true

func _start_lifetime_timer(node : Node, life_time : float) -> void:
	if life_time <= 0.0:
		return
	get_tree().create_timer(life_time).timeout.connect(func():
		if is_instance_valid(node):
			node.queue_free()
	)

func _get_bodies_in_radius(radius : float) -> Array:
	var space   := get_world_3d().direct_space_state
	var query   := PhysicsShapeQueryParameters3D.new()
	var sphere  := SphereShape3D.new()
	sphere.radius = radius
	query.shape          = sphere
	query.transform      = Transform3D(Basis.IDENTITY, entity.global_position)
	query.collision_mask = int(pow(2, 2)) + int(pow(2, 4))  # players + monsters layers
	var hits := space.intersect_shape(query)
	var result := []
	for h in hits:
		result.append(h["collider"])
	return result

func _notify_hud_cooldown_start(ability : Ability) -> void:
	if not entity.is_in_group("player"):
		return
	for slot in entity.hud.ability_list.get_children():
		if slot.ability == ability:
			slot.start_cooldown()
			break
