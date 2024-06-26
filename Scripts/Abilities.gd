extends Node

@onready var cutting_around_col = $cutting_around
@onready var cutting_around_visual = $CuttingAroundVisual
@onready var stone_pounding_col = $stone_pounding
@onready var stone_pounding_visual = $StonePoundingVisual
@onready var edifying_impact_col = $edifying_impact
@onready var edifying_impact_visual = $EdifyingImpactVisual

const OMNISCIENT_GOLEM = preload("res://Ressources/Monsters/OmniscientGolem.tres")
const BLIND_BRUTE = preload("res://Ressources/Monsters/BlindBrute.tres")

var in_animation : bool

const CUTTING_AROUND_MAX_DAMAGE = 50
func cutting_around(ability_dealer : Object):
	if !in_animation:
		in_animation = true
		cutting_around_visual.set_visible(true)
		get_tree().create_timer(0.5).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			cutting_around_visual.set_visible(false)
			in_animation = false
			for p in cutting_around_col.get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(min(ability_dealer.physical_damage, CUTTING_AROUND_MAX_DAMAGE), 0, ability_dealer)))

func stone_pounding(ability_dealer : Object):
	if !in_animation:
		in_animation = true
		stone_pounding_visual.set_visible(true)
		ability_dealer.update_path(true)
		ability_dealer.update_path_timer.stop()
		get_tree().create_timer(1.5).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			stone_pounding_visual.set_visible(false)
			in_animation = false
			ability_dealer.update_path()
			ability_dealer.update_path_timer.start()
			for p in stone_pounding_col.get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(OMNISCIENT_GOLEM.physical_damage, 0, ability_dealer)))

func edifying_impact(ability_dealer : Object):
	if !in_animation:
		in_animation = true
		edifying_impact_visual.set_visible(true)
		get_tree().create_timer(0.5).timeout.connect(Callable(func():
			if ability_dealer.is_dead():
				return
			edifying_impact_visual.set_visible(false)
			in_animation = false
			for p in edifying_impact_col.get_overlapping_bodies():
				if p != ability_dealer:
					p.take_damage(BLIND_BRUTE.physical_damage, 0, ability_dealer)))

func get_spell_range(spell : String) -> float:
	return get_node(spell).get_node("Collision").shape.get("radius")
