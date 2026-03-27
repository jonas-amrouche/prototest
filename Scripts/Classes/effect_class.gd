class_name Effect
extends Resource

@export var id          : StringName
@export_multiline var description : String
@export var icon        : Texture2D
@export var duration    : float = 0.0
@export var debuff      : bool  = false

@export var stat_modifiers : Dictionary = {}

@export var custom_data : Array = []  ## Escape hatch for per-effect data that doesn't fit stat_modifiers.
