extends Node

@onready var cutting_around_visual = $CuttingAroundVisual
@onready var stone_pounding_visual = $StonePoundingVisual
@onready var edifying_impact_visual = $EdifyingImpactVisual
@onready var haunting_shot_visual = $HauntingShotVisual
@onready var angry_headbutt_visual = $AngryHeadbuttVisual

const OMNISCIENT_GOLEM = preload("res://Ressources/Monsters/OmniscientGolem.tres")
const BLIND_BRUTE = preload("res://Ressources/Monsters/BlindBrute.tres")
const DISPOSSESSED_WILLOW = preload("res://Ressources/Monsters/DispossessedWillow.tres")
const GRUNTER = preload("res://Ressources/Monsters/Grunter.tres")
const LOST_GHOST = preload("res://Ressources/Monsters/LostGhost.tres")

var in_animation : bool

func use_ability(ability : Ability, ability_dealer : Object) -> void:
	call(ability.id, ability, ability_dealer)

func cutting_around(ability : Ability, ability_dealer : Object):
	if !in_animation:
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
			in_animation = false))

func stone_pounding(ability : Ability, ability_dealer : Object):
	if !in_animation:
		in_animation = true
		stone_pounding_visual.set_visible(true)
		ability_dealer.update_path(true)
		ability_dealer.update_path_timer.stop()
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			stone_pounding_visual.set_visible(false)
			in_animation = false
			ability_dealer.update_path()
			ability_dealer.update_path_timer.start()
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(OMNISCIENT_GOLEM.physical_damage, 0, ability_dealer)))

func edifying_impact(ability : Ability, ability_dealer : Object):
	if !in_animation:
		in_animation = true
		edifying_impact_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			edifying_impact_visual.set_visible(false)
			in_animation = false
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(BLIND_BRUTE.physical_damage, 0, ability_dealer)))

func haunting_shot(ability : Ability, ability_dealer : Object):
	if !in_animation:
		in_animation = true
		haunting_shot_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			haunting_shot_visual.set_visible(false)
			in_animation = false
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(DISPOSSESSED_WILLOW.magic_damage, 1, ability_dealer)))

func angry_headbutt(ability : Ability, ability_dealer : Object):
	if !in_animation:
		in_animation = true
		angry_headbutt_visual.set_visible(true)
		get_tree().create_timer(ability.attack_time).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			angry_headbutt_visual.set_visible(false)
			in_animation = false
			for p in get_spell_col(ability.id).get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(GRUNTER.magic_damage, 1, ability_dealer)))

func get_spell_col(spell : String) -> Object:
	return get_node(spell)

func get_spell_range(spell : String) -> float:
	return get_node(spell).get_node("Collision").shape.get("radius")
