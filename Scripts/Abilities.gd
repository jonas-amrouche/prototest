extends Node

@onready var cutting_around_visual = $CuttingAroundVisual
@onready var stone_pounding_visual = $StonePoundingVisual
@onready var edifying_impact_visual = $EdifyingImpactVisual
@onready var haunting_shot_visual = $HauntingShotVisual
@onready var angry_headbutt_visual = $AngryHeadbuttVisual
@onready var big_forward_cut_visual = $BigForwardCutVisual

const OMNISCIENT_GOLEM = preload("res://Ressources/Monsters/OmniscientGolem.tres")
const BLIND_BRUTE = preload("res://Ressources/Monsters/BlindBrute.tres")
const DISPOSSESSED_WILLOW = preload("res://Ressources/Monsters/DispossessedWillow.tres")
const GRUNTER = preload("res://Ressources/Monsters/Grunter.tres")
const LOST_GHOST = preload("res://Ressources/Monsters/LostGhost.tres")

var in_animation : bool

func use_ability(ability : Ability, ability_dealer : Object) -> void:
	call(ability.id, ability, ability_dealer)

var cutting_around_cooldown = false
func cutting_around(ability : Ability, ability_dealer : Object):
	if !in_animation and !cutting_around_cooldown:
		in_animation = true
		ability_dealer.lose_strength(ability.strength_cost)
		cutting_around_visual.set_visible(true)
		for p in get_spell_col(ability.id).get_overlapping_bodies():
			if p != ability_dealer:
				p.take_damage(min(ability_dealer.physical_damage, ability.physical_damage_cap), 0, ability_dealer)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			cutting_around_visual.set_visible(false)
			in_animation = false
			cutting_around_cooldown = true
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				cutting_around_cooldown = false))))

var big_forward_cut_cooldown = false
func big_forward_cut(ability : Ability, ability_dealer : Object):
	if !in_animation and !cutting_around_cooldown:
		in_animation = true
		ability_dealer.lose_strength(ability.strength_cost)
		big_forward_cut_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			big_forward_cut_visual.set_visible(false)
			in_animation = false
			big_forward_cut_cooldown = true
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(min(ability_dealer.physical_damage, ability.physical_damage_cap), 0, ability_dealer)
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				big_forward_cut_cooldown = false))))

var stone_pounding_cooldown = false
func stone_pounding(ability : Ability, ability_dealer : Object):
	if !in_animation and !stone_pounding_cooldown:
		in_animation = true
		stone_pounding_visual.set_visible(true)
		ability_dealer.update_path(true)
		ability_dealer.update_path_timer.stop()
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			stone_pounding_visual.set_visible(false)
			in_animation = false
			stone_pounding_cooldown = true
			ability_dealer.update_path()
			ability_dealer.update_path_timer.start()
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(OMNISCIENT_GOLEM.physical_damage, 0, ability_dealer)
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				stone_pounding_cooldown = false))))

var edifying_impact_cooldown = false
func edifying_impact(ability : Ability, ability_dealer : Object):
	if !in_animation and !edifying_impact_cooldown:
		in_animation = true
		edifying_impact_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			edifying_impact_visual.set_visible(false)
			in_animation = false
			edifying_impact_cooldown = true
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(BLIND_BRUTE.physical_damage, 0, ability_dealer)
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				edifying_impact_cooldown = false))))

var haunting_shot_cooldown = false
func haunting_shot(ability : Ability, ability_dealer : Object):
	if !in_animation and !haunting_shot_cooldown:
		in_animation = true
		haunting_shot_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			haunting_shot_visual.set_visible(false)
			in_animation = false
			haunting_shot_cooldown = true
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(DISPOSSESSED_WILLOW.magic_damage, 1, ability_dealer)
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				haunting_shot_cooldown = false))))

var angry_headbutt_cooldown = false
func angry_headbutt(ability : Ability, ability_dealer : Object):
	if !in_animation and !angry_headbutt_cooldown:
		in_animation = true
		angry_headbutt_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			angry_headbutt_visual.set_visible(false)
			in_animation = false
			angry_headbutt_cooldown = true
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(GRUNTER.magic_damage, 1, ability_dealer)
			get_tree().create_timer(ability.cooldown).timeout.connect(Callable(func():
				angry_headbutt_cooldown = false))))

func get_spell_col(spell : String) -> Object:
	return get_node(spell)

func get_spell_range(spell : String) -> float:
	if get_node(spell).get_node("Collision").shape.is_class("CylinderShape3D"):
		return get_node(spell).get_node("Collision").shape.get("radius")
	else:
		print(get_node(spell).get_node("Collision").shape.get("size").z/2.0 + get_node(spell).get_node("Collision").position.z)
		return get_node(spell).get_node("Collision").shape.get("size").z/2.0 + get_node(spell).get_node("Collision").position.z
