## Item — an item carried in a player's inventory or bound to the ability bar.
##
## Stats are stored as a Dictionary matching Entity's stat map.
## Active items move from inventory to the ability bar when bound —
## they leave the inventory entirely and occupy a bar slot.
##
## Evolution system:
## Each stat has a visible cap in stat_caps. Combining two items transfers
## stats from one into the other, pushing toward those caps. When a stat
## reaches its cap, the item may evolve into evolved_item.
## Evolution paths are hidden — the result only appears in the craft output
## slot when both inputs are placed (Minecraft-style preview).
## Combined items cannot be reverted.

class_name Item
extends Resource

# ── Identity ──────────────────────────────────────────────────────────────────

@export var display_name : String
@export_multiline var description : String

# ── Icons ─────────────────────────────────────────────────────────────────────
## Two art pieces per item.
## icon_active   — ability art. Shown in bar slot when ability is ready.
##                 Full energy, open, alive. Communicates "use me now."
## icon_resting  — item art. Shown when on cooldown or unavailable.
##                 Subdued, waiting. Communicates "not ready."

@export var icon_active  : Texture2D
@export var icon_resting : Texture2D

# ── 3D model ──────────────────────────────────────────────────────────────────
## Scene instantiated and attached to the player rig when this item is bound.
## socket_preference declares which attachment point this item prefers.
## If the preferred socket is occupied, the system falls back to the next available.

@export var model_scene       : PackedScene
@export var socket_preference : Basics.ItemSocket = Basics.ItemSocket.HAND_RIGHT

# ── Type and rarity ───────────────────────────────────────────────────────────

@export var type   : Basics.ItemType
@export var rarity : Basics.Rarity

# ── Stats this item contributes ───────────────────────────────────────────────
## Keys match stat IDs from Entity constants (Entity.S_PHYSICAL etc.)
## Values are the flat bonus this item gives to the character sheet.
## Example: { "physical": 40, "max_health": 80 }
## Passive items in inventory contribute stats directly.
## Active items contribute stats when bound to the ability bar.

@export var stats : Dictionary = {}

# ── Stat caps for evolution ───────────────────────────────────────────────────
## Maps stat_id -> cap value.
## When stats[stat_id] reaches stat_caps[stat_id], evolution check fires.
## A cap of 0 means that stat has no evolution trigger on this item.

@export var stat_caps : Dictionary = {}

# ── Evolution ─────────────────────────────────────────────────────────────────
## The item this evolves into when a capped stat is reached.
## Null means no evolution exists through this stat path — not an error,
## just information. The player now knows this item's limit in this direction.

@export var evolved_item : Item = null

# ── Crafting ──────────────────────────────────────────────────────────────────
## The two items needed to combine into this item.
## Order does not matter — the system checks both permutations.

@export var craft : Array[Item] = []

# ── Abilities and passives ────────────────────────────────────────────────────
## Abilities become available when this item is bound to the ability bar.
## Passives apply as long as the item is anywhere in inventory or bar.

@export var abilities : Array[Ability] = []
@export var passives  : Array[Passive] = []

# ── Evolution logic ───────────────────────────────────────────────────────────

## Transfers stats from donor into this item, capped by stat_caps.
## Returns evolved_item if any cap was reached, null if not.
func combine_stats_from(donor : Item) -> Item:
	var evolved := false
	for stat_id in donor.stats:
		var delta   : int = donor.stats[stat_id]
		var current : int = stats.get(stat_id, 0)
		var cap     : int = stat_caps.get(stat_id, 0)
		
		if cap > 0:
			stats[stat_id] = min(current + delta, cap)
			if stats[stat_id] >= cap:
				evolved = true
		else:
			stats[stat_id] = current + delta
	
	return evolved_item if evolved else null

## Returns true if this item can be crafted from the two given items.
func is_craftable_from(a : Item, b : Item) -> bool:
	if craft.size() != 2:
		return false
	return (craft[0] == a and craft[1] == b) or (craft[0] == b and craft[1] == a)

## Returns progress of the stat closest to its cap, as a fraction 0.0-1.0.
## Returns -1.0 if no caps are defined on this item.
func get_closest_cap_progress() -> float:
	var best : float = -1.0
	for stat_id in stat_caps:
		var cap : int = stat_caps[stat_id]
		if cap <= 0:
			continue
		var progress : float = float(stats.get(stat_id, 0)) / float(cap)
		if progress > best:
			best = progress
	return best
