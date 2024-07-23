extends Control

@export var color : Color = Color(0.638, 0.117, 0)
@onready var health_bar = $HealthBar

func _ready():
	health_bar.get("theme_override_styles/fill").set("bg_color", color)
