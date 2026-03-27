## Basics — global constants, enums, and utility functions.
## Autoloaded as "Basics" in project settings.

extends Node

# ── Map ───────────────────────────────────────────────────────────────────────

const MAP_SIZE := Vector2(150.0, 150.0)

## Global Rythic scaling rate. Tune this once against prototype action times.
## damage_bonus = rythic × action_time × RYTHIC_RATE
## Example: 100 Rythic on a 1.0s cast with rate 0.5 adds 50 bonus damage.
const RYTHIC_RATE := 0.5

# ── Enums ─────────────────────────────────────────────────────────────────────

enum EntityType   { PLAYER, MONSTER, NPCS, ITEM, GUARDS, STRUCTURE }
enum ItemType     { ITEM, COMPONENTS, CONSUMABLE }
enum SlotType     { INVENTORY, BAR, CRAFT, CONSUMABLE }
enum Rarity       { CLASSIC, RARE, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL }
enum ClientState  { DISCONNECTED, ENTERED, LOADING, INGAME }
enum CursorMode   { NORMAL, ATTACK, LOOT }

enum DamageType   { PHYSICAL, TENSION, WITHERING }

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

## Attachment points on the player rig for bound item models.
## Items declare a socket_preference — system falls back if occupied.
enum ItemSocket {
	HAND_RIGHT,  ## Primary weapon hand
	HAND_LEFT,   ## Off-hand
	BACK,        ## Back/shoulders
	HIP_LEFT,    ## Belt left
	HIP_RIGHT,   ## Belt right
	CHEST,       ## Body/chest
	HEAD,        ## Head
	WRIST,       ## Wrist/bracers
}

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
	## Damage
	"rythic"            : Color.FIREBRICK,
	"physical"          : Color.INDIAN_RED,
	"tension"           : Color.CORNFLOWER_BLUE,
	"withering"         : Color.MEDIUM_PURPLE,
	## Defense
	"physical_armor"    : Color.BROWN,
	"tension_armor"     : Color.STEEL_BLUE,
	"withering_armor"   : Color.DARK_SLATE_BLUE,
	"shield"            : Color.SILVER,
	"tenacity"          : Color.ROSY_BROWN,
	## Sustain
	"max_health"        : Color.DARK_GREEN,
	"health_regen"      : Color.SEA_GREEN,
	"shield_regen"      : Color.LIGHT_STEEL_BLUE,
	"life_steal"        : Color.DARK_RED,
	## Mobility
	"movement_speed"    : Color.KHAKI,
	"move_reduction"    : Color.DARK_KHAKI,
	## Utility
	"cooldown_reduction": Color.MEDIUM_ORCHID,
	"attack_speed"      : Color.GOLD,
	"veil"              : Color.LIGHT_CYAN,
	"looting"           : Color.SANDY_BROWN,
	## Combat specialization
	"monster_damage"    : Color.ORANGE_RED,
	"monster_resistance": Color.DARK_OLIVE_GREEN,
}

## Maps DamageType enum index → display color
const DAMAGE_COLORS : Array[Color] = [
	Color.INDIAN_RED,    ## PHYSICAL
	Color.CORNFLOWER_BLUE, ## TENSION
	Color.MEDIUM_PURPLE, ## WITHERING
]

const CLASS_TEXT : Array[String] = [
	"bleeder", "tracker", "tender", "breaker", "drifter"
]

# ── Resource loaders ──────────────────────────────────────────────────────────
## Called once at startup by GameResources._ready(). Never call per-frame.

func load_all_items() -> Array[Item]:
	var results : Array[Item] = []
	var dir := DirAccess.open("res://Resources/Items/")
	if not dir:
		push_error("Basics: could not open res://Resources/Items/")
		return results
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".tres"):
			var res = load("res://Resources/Items/" + file_name)
			if res is Item:
				results.append(res)
		file_name = dir.get_next()
	return results
