class_name Entity
extends Resource

@export var id          : StringName
@export var entity_type : Basics.EntityType
@export var icon        : Texture2D

var health : int = 0
var shield : int = 0
var souls  : int = 0

signal state_changed

@export var base_stats : Dictionary = {}

var stats : Dictionary = {}  ## Recomputed each update_stats(). Never write directly.

func get_stat(stat_id : StringName) -> int:
	return stats.get(stat_id, 0)

func set_stat(stat_id : StringName, value : int) -> void:
	stats[stat_id] = value

func add_stat(stat_id : StringName, delta : int) -> void:
	stats[stat_id] = stats.get(stat_id, 0) + delta

func reset_stats() -> void:
	stats = {}
	for key in base_stats:
		stats[StringName(key)] = base_stats[key]

const S_RYTHIC          : StringName = &"rythic"
const S_PHYSICAL        : StringName = &"physical"
const S_TENSION         : StringName = &"tension"
const S_WITHERING       : StringName = &"withering"
const S_PHYSICAL_ARMOR  : StringName = &"physical_armor"
const S_TENSION_ARMOR   : StringName = &"tension_armor"
const S_WITHERING_ARMOR : StringName = &"withering_armor"
const S_SHIELD          : StringName = &"shield"
const S_TENACITY        : StringName = &"tenacity"
const S_MAX_HEALTH      : StringName = &"max_health"
const S_HEALTH_REGEN    : StringName = &"health_regen"
const S_SHIELD_REGEN    : StringName = &"shield_regen"
const S_LIFE_STEAL      : StringName = &"life_steal"
const S_MOVEMENT_SPEED  : StringName = &"movement_speed"
const S_MOVE_REDUCTION  : StringName = &"move_reduction"
const S_COOLDOWN_RED    : StringName = &"cooldown_reduction"
const S_ATTACK_SPEED    : StringName = &"attack_speed"
const S_VEIL            : StringName = &"veil"
const S_LOOTING         : StringName = &"looting"
const S_MONSTER_DAMAGE  : StringName = &"monster_damage"
const S_MONSTER_RESIST  : StringName = &"monster_resistance"

func get_rythic()          -> int: return get_stat(S_RYTHIC)
func get_physical()        -> int: return get_stat(S_PHYSICAL)
func get_tension()         -> int: return get_stat(S_TENSION)
func get_withering()       -> int: return get_stat(S_WITHERING)
func get_physical_armor()  -> int: return get_stat(S_PHYSICAL_ARMOR)
func get_tension_armor()   -> int: return get_stat(S_TENSION_ARMOR)
func get_withering_armor() -> int: return get_stat(S_WITHERING_ARMOR)
func get_shield_max()      -> int: return get_stat(S_SHIELD)
func get_tenacity()        -> int: return get_stat(S_TENACITY)
func get_max_health()      -> int: return get_stat(S_MAX_HEALTH)
func get_health_regen()    -> int: return get_stat(S_HEALTH_REGEN)
func get_shield_regen()    -> int: return get_stat(S_SHIELD_REGEN)
func get_life_steal()      -> int: return get_stat(S_LIFE_STEAL)
func get_movement_speed()  -> int: return get_stat(S_MOVEMENT_SPEED)
func get_move_reduction()  -> int: return get_stat(S_MOVE_REDUCTION)
func get_cooldown_red()    -> int: return get_stat(S_COOLDOWN_RED)
func get_attack_speed()    -> int: return get_stat(S_ATTACK_SPEED)
func get_veil()            -> int: return get_stat(S_VEIL)
func get_looting()         -> int: return get_stat(S_LOOTING)
func get_monster_damage()  -> int: return get_stat(S_MONSTER_DAMAGE)
func get_monster_resist()  -> int: return get_stat(S_MONSTER_RESIST)

func set_full_health() -> void:
	health = get_max_health()
	shield = 0
	state_changed.emit()

func set_health(hp : int) -> void:
	health = clamp(hp, 0, get_max_health())
	state_changed.emit()

func set_shield(s : int) -> void:
	shield = clamp(s, 0, get_shield_max())
	state_changed.emit()

func is_alive() -> bool:
	return health > 0
