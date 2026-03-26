## Basics — global constants, enums, and utility functions.
## Autoloaded as "Basics" in project settings.

extends Node

# ── Map ───────────────────────────────────────────────────────────────────────

const MAP_SIZE := Vector2(150.0, 150.0)

# ── Enums ─────────────────────────────────────────────────────────────────────

enum EntityType   { PLAYER, MONSTER, NPCS, ITEM, GUARDS, STRUCTURE }
enum ItemType     { ITEM, COMPONENTS, CONSUMABLE }
enum SlotType     { INVENTORY, CRAFT, CONSUMABLE }
enum Rarity       { CLASSIC, RARE, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL }
enum ClientState  { DISCONNECTED, ENTERED, LOADING, INGAME }
enum CursorMode   { NORMAL, ATTACK, LOOT }

enum DamageType   { PHYSIC, MAGIC, HYBRID }

## Ability execution types. Each maps to a handler in the AbilityMachine.
enum AbilityType  {
	TARGETED,    ## Fires at selected target
	SKILLSHOT,   ## Fires toward cursor position
	AREA,        ## Affects all enemies in radius around caster
	TOGGLE,      ## On/off, ticked each frame while active
	PASSIVE      ## Never cast, applied automatically
}

enum AbilityError {
	OK,
	IN_COOLDOWN,
	NO_TARGET,
	OUT_OF_RANGE,
	UNAVAILABLE,
	SCRIPT_ERROR
}

enum AbilityCancel { MOVING, TAKING_DAMAGE }

enum ClassType {
	BLEEDER,
	TRACKER,
	TENDER,
	BREAKER,
	DRIFTER,
}

# ── Text / color tables ───────────────────────────────────────────────────────

const RARITY_TEXT : Array[String] = [
	"classic", "rare", "elite", "fantastic",
	"legendary", "mythical", "theoretical"
]

const RARITY_COLORS : Array[Color] = [
	Color(0.0,  0.0,   0.0),
	Color(0.0,  0.275, 0.0),
	Color(0.0,  0.162, 0.27),
	Color(0.27, 0.153, 0.0),
	Color(0.27, 0.27,  0.0),
	Color(0.27, 0.009, 0.0),
	Color(0.27, 0.27,  0.27)
]

## Stat ID → display color. Add new entries here when adding stats.
## Keys match the stat IDs used in Entity.stats and Item.stats.
const STAT_COLORS : Dictionary = {
	"rythic"              : Color.FIREBRICK,
	"ember"               : Color.DARK_GREEN,
	"veil"                : Color.CORNFLOWER_BLUE,
	"stride"              : Color.DARK_SLATE_BLUE,
	"lull"                : Color.MEDIUM_PURPLE,
	"physical_damage"     : Color.FIREBRICK,
	"magic_damage"        : Color.SLATE_BLUE,
	"physical_armor"      : Color.BROWN,
	"magic_armor"         : Color.DARK_SLATE_BLUE,
	"health_regeneration" : Color.SEA_GREEN,
	"movement_speed"      : Color.DARK_SLATE_BLUE,
	"life_steal"          : Color.DARK_RED,
}

const DAMAGE_COLORS : Array[Color] = [Color.FIREBRICK, Color.SLATE_BLUE]

const CLASS_TEXT : Array[String] = [
	"bleeder", "tracker", "tender", "breaker", "drifter"
]

# ── Resource loaders ──────────────────────────────────────────────────────────
## Called once at startup by GameResources. Results are cached there.
## Do not call these per-frame.

func load_all_items() -> Array[Item]:
	return _load_resources_from("res://Resources/Items/", "Item")

func load_all_stats() -> Dictionary:
	var result : Dictionary = {}
	for stat in _load_resources_from("res://Resources/Stats/", "Stat"):
		result[stat.id] = stat
	return result

func load_all_abilities() -> Dictionary:
	var result : Dictionary = {}
	for ab in _load_resources_from("res://Resources/Abilities/", "Ability"):
		result[ab.id] = ab
	return result

func _load_resources_from(path : String, _type_hint : String) -> Array:
	var results := []
	var dir := DirAccess.open(path)
	if not dir:
		push_error("Basics: could not open resource directory: " + path)
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load(path + file_name)
			if res:
				results.append(res)
		file_name = dir.get_next()
	return results
