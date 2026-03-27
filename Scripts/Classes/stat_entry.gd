class_name StatEntry
extends Resource

@export var id    : StringName = &""
@export var value : float      = 0.0
@export var cap   : float      = 0.0  ## 0.0 = no cap, stat grows freely

func has_cap() -> bool:
	return cap > 0.0

func is_at_cap() -> bool:
	return cap > 0.0 and value >= cap

func progress() -> float:
	if cap <= 0.0:
		return -1.0
	return clampf(value / cap, 0.0, 1.0)
