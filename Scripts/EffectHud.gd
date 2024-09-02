extends PanelContainer

@export var effect : Effect

signal mouse_entered_effect(eff : Effect)

@onready var icon := $Pad/Icon

func _ready():
	update_effect()

func update_effect() -> void:
	if effect:
		icon.texture = effect.icon
	else:
		icon.texture = null

func _on_mouse_entered():
	mouse_entered_effect.emit(effect)
