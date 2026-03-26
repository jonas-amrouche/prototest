## Item — an item carried in a player's inventory.
##
## Stats are stored as a Dictionary matching Entity's stat map.
## The evolution system lives here: each stat has a visible cap,
## and when a stat reaches its cap the item may evolve into a new one.
##
## Evolution paths are intentionally hidden from the player —
## evolved_item is only revealed in the crafting result slot when
## both input items are placed and the threshold is met (Minecraft-style).
##
## craft[] lists the two items needed to combine into this item.
## stat_caps{} maps stat_id -> cap value for this item.
## When any stat hits its cap, check_evolution() is called.

class_name Item
extends Resource

# ── Identity ──────────────────────────────────────────────────────────────────

@export var id          : String
@export var display_name: String
@export_multiline var description : String
@export var icon        : Texture2D
@export var mesh_model  : PackedScene
@export var type        : Basics.ItemType
@export var rarity      : Basics.Rarity

# ── Stats this item contributes ───────────────────────────────────────────────
## Keys match stat IDs. Values are the flat bonus this item gives.
## Example: { "rythic": 30, "ember": 50 }

@export var stats : Dictionary = {}

# ── Stat caps for evolution ───────────────────────────────────────────────────
## Maps stat_id -> cap value.
## If stats[stat_id] reaches stat_caps[stat_id], an evolution check fires.
## A cap of 0 means that stat has no evolution trigger on this item.

@export var stat_caps : Dictionary = {}

# ── Evolution ─────────────────────────────────────────────────────────────────
## The item this evolves into when any capped stat is reached.
## Null means no evolution exists through the current stat path.
## Intentionally a single target — the stat that triggered the cap
## is carried forward into the evolved item as its foundation.

@export var evolved_item : Item = null

# ── Crafting ──────────────────────────────────────────────────────────────────
## Exactly two items needed to combine into this item.
## Order does not matter — the system checks both permutations.

@export var craft : Array[Item] = []

# ── Abilities and passives ────────────────────────────────────────────────────

@export var abilities : Array[Ability] = []
@export var passives  : Array[Passive] = []

# ── Evolution logic ───────────────────────────────────────────────────────────

## Call this after combining two items into this one.
## Transfers stats from the donor into this item, capped by stat_caps.
## Returns the evolved item if a cap was reached, or null if not.
func combine_stats_from(donor : Item) -> Item:
	for stat_id in donor.stats:
		var delta     : int = donor.stats[stat_id]
		var current   : int = stats.get(stat_id, 0)
		var cap       : int = stat_caps.get(stat_id, 0)

		if cap > 0:
			stats[stat_id] = min(current + delta, cap)
			if stats[stat_id] >= cap:
				return evolved_item  # may be null — caller handles both cases
		else:
			stats[stat_id] = current + delta

	return null

## Returns true if this item can be crafted from the two given items.
## Order-independent.
func is_craftable_from(a : Item, b : Item) -> bool:
	if craft.size() != 2:
		return false
	return (craft[0] == a and craft[1] == b) or (craft[0] == b and craft[1] == a)

## Returns the stat that is closest to its cap as a fraction 0.0–1.0.
## Used by UI to decide whether to show the evolution preview slot.
## Returns -1.0 if no caps are defined.
func get_closest_cap_progress() -> float:
	var best : float = -1.0
	for stat_id in stat_caps:
		var cap : int = stat_caps[stat_id]
		if cap <= 0:
			continue
		var current : int = stats.get(stat_id, 0)
		var progress : float = float(current) / float(cap)
		if progress > best:
			best = progress
	return best
