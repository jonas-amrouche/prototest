class_name Passive
extends Resource

## id is the contract — check has_passive(id) to gate conditional behaviour.
@export var id          : StringName
@export_multiline var description : String
@export var color       : Color
@export var icon        : Texture2D

@export var stat_modifiers : Dictionary = {}
