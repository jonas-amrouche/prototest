## Entity — core data container for any living thing in the world.
## Stats are stored in a Dictionary keyed by stat ID string.
## Adding a new stat never requires touching this file —
## add a constant below, a getter, and reference it everywhere.
##
## Health and shield are first-class fields because they are runtime state
## with special clamping logic, not base stats.
## souls is match-state, not a base stat.

class_name Entity
extends Resource

# ── Identity ─────────────────────────────────────────────────────────────────

@export var id          : String
@export var entity_type : Basics.EntityType
@export var icon        : Texture2D

# ── Runtime state (not stats) ─────────────────────────────────────────────────

var health : int = 0
var shield : int = 0  ## Bonus HP, only regenerates out of combat
var souls  : int = 0

signal state_changed

# ── Base stats ────────────────────────────────────────────────────────────────
## Exported Dictionary — populate base values in the Godot inspector.
## Keys must match the S_* constants below exactly.
## Example: { "max_health": 500, "physical": 40, "movement_speed": 60 }

@export var base_stats : Dictionary = {}

# ── Runtime stat map ──────────────────────────────────────────────────────────
## Recomputed on every update_stats() call. Never write directly.

var stats : Dictionary = {}

# ── Stat access ───────────────────────────────────────────────────────────────

func get_stat(stat_id : String) -> int:
	return stats.get(stat_id, 0)

func set_stat(stat_id : String, value : int) -> void:
	stats[stat_id] = value

func add_stat(stat_id : String, delta : int) -> void:
	stats[stat_id] = stats.get(stat_id, 0) + delta

func reset_stats() -> void:
	stats = base_stats.duplicate()

# ── Stat ID constants ─────────────────────────────────────────────────────────

## Damage
const S_RYTHIC          := "rythic"
const S_PHYSICAL        := "physical"
const S_TENSION         := "tension"
const S_WITHERING       := "withering"

## Defense
const S_PHYSICAL_ARMOR  := "physical_armor"
const S_TENSION_ARMOR   := "tension_armor"
const S_WITHERING_ARMOR := "withering_armor"
const S_SHIELD          := "shield"
const S_TENACITY        := "tenacity"

## Sustain
const S_MAX_HEALTH      := "max_health"
const S_HEALTH_REGEN    := "health_regen"
const S_SHIELD_REGEN    := "shield_regen"
const S_LIFE_STEAL      := "life_steal"

## Mobility
const S_MOVEMENT_SPEED  := "movement_speed"
const S_MOVE_REDUCTION  := "move_reduction"

## Utility
const S_COOLDOWN_RED    := "cooldown_reduction"
const S_ATTACK_SPEED    := "attack_speed"
const S_VEIL            := "veil"
const S_LOOTING         := "looting"

## Combat specialization
const S_MONSTER_DAMAGE  := "monster_damage"
const S_MONSTER_RESIST  := "monster_resistance"

# ── Convenience getters ───────────────────────────────────────────────────────

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

# ── Health / shield helpers ───────────────────────────────────────────────────

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
