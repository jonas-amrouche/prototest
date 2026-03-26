## Entity — core data container for any living thing in the world.
## Stats are stored in a Dictionary keyed by stat ID string.
## This means adding a new stat never requires touching this file —
## just add a new Stat resource and reference its ID everywhere.
##
## Health is kept as a first-class field because it is runtime state,
## not a base stat, and it needs special clamping logic.
##
## souls is also kept separately — it is match-state, not a base stat.

class_name Entity
extends Resource

# ── Identity ─────────────────────────────────────────────────────────────────

@export var id           : String
@export var entity_type  : Basics.EntityType
@export var icon         : Texture2D

# ── Health (runtime, not a stat) ──────────────────────────────────────────────

var health : int = 0
var souls  : int = 0

signal state_changed

# ── Base stats ────────────────────────────────────────────────────────────────
## Exported as a Dictionary so the Godot inspector can populate base values.
## Keys must match the IDs of your Stat resources exactly.
## Example: { "ember": 500, "rythic": 40, "stride": 60 }

@export var base_stats : Dictionary = {}

# ── Runtime stat map ──────────────────────────────────────────────────────────
## Computed each time update_stats() is called on the owner.
## Never write to this directly — it is always derived.

var stats : Dictionary = {}

# ── Stat access helpers ───────────────────────────────────────────────────────

## Read a stat value by ID. Returns 0 if the stat does not exist.
func get_stat(stat_id : String) -> int:
	return stats.get(stat_id, 0)

## Write a computed stat value. Used by the owner during update_stats().
func set_stat(stat_id : String, value : int) -> void:
	stats[stat_id] = value

## Add a delta to a computed stat. Used when applying item bonuses in a loop.
func add_stat(stat_id : String, delta : int) -> void:
	stats[stat_id] = stats.get(stat_id, 0) + delta

## Reset all computed stats back to base values.
## Call this at the start of every update_stats() pass.
func reset_stats() -> void:
	stats = base_stats.duplicate()

# ── Convenience shorthands ────────────────────────────────────────────────────
## These match the GDD stat unit names. They are just thin wrappers around
## get_stat() so call sites read naturally without magic strings everywhere.

func get_ember()  -> int: return get_stat("ember")    # max health
func get_rythic() -> int: return get_stat("rythic")   # damage
func get_veil()   -> int: return get_stat("veil")     # vision range
func get_stride() -> int: return get_stat("stride")   # movement speed
func get_lull()   -> int: return get_stat("lull")     # cooldown reduction

# Physical / magic split stats kept for combat clarity.
func get_physical_damage() -> int: return get_stat("physical_damage")
func get_magic_damage()    -> int: return get_stat("magic_damage")
func get_physical_armor()  -> int: return get_stat("physical_armor")
func get_magic_armor()     -> int: return get_stat("magic_armor")
func get_max_health()      -> int: return get_stat("ember")
func get_movement_speed()  -> int: return get_stat("stride")
func get_health_regen()    -> int: return get_stat("health_regeneration")
func get_life_steal()      -> int: return get_stat("life_steal")

# ── Health helpers ────────────────────────────────────────────────────────────

func set_full_health() -> void:
	health = get_max_health()
	state_changed.emit()

func set_health(hp : int) -> void:
	health = clamp(hp, 0, get_max_health())
	state_changed.emit()

func is_alive() -> bool:
	return health > 0
