class_name Item
extends Resource

@export var item_id      : StringName = &""
@export var display_name : String
@export_multiline var description : String

@export var icon_active  : Texture2D
@export var icon_resting : Texture2D

@export var model_scene       : PackedScene
@export var socket_preference : Basics.ItemSocket = Basics.ItemSocket.HAND_RIGHT

@export var type   : Basics.ItemType
@export var rarity : Basics.Rarity

@export var stats : Array[StatEntry] = []

@export var evolved_item : Item = null

@export var abilities : Array[Ability] = []
@export var passives  : Array[Passive] = []

func is_valid() -> bool:
	return item_id != &""

func is_same_item(other : Item) -> bool:
	return item_id != &"" and item_id == other.item_id

func get_stat_entry(stat_id : StringName) -> StatEntry:
	for entry in stats:
		if entry.id == stat_id:
			return entry
	return null

func get_stat_value(stat_id : StringName) -> float:
	var entry := get_stat_entry(stat_id)
	return entry.value if entry else 0.0

## Call on a duplicate — mutates stats in place.
func combine_stats_from(donor : Item) -> Item:
	var evolved := false
	for donor_entry in donor.stats:
		var entry := get_stat_entry(donor_entry.id)
		if entry:
			if entry.has_cap():
				entry.value = minf(entry.value + donor_entry.value, entry.cap)
				if entry.is_at_cap():
					evolved = true
			else:
				entry.value += donor_entry.value
		else:
			var absorbed := StatEntry.new()
			absorbed.id    = donor_entry.id
			absorbed.value = donor_entry.value
			stats.append(absorbed)
	return evolved_item if evolved else null

func get_closest_cap_progress() -> float:
	var best : float = -1.0
	for entry in stats:
		var p := entry.progress()
		if p > best:
			best = p
	return best
