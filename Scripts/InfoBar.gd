extends Control

@export var second_bar : bool = false
@export var color : Color = Color(0.638, 0.117, 0)
@onready var health_bar = $HealthBar
@onready var strength_bar = $StrengthBar

func _ready():
	strength_bar.set_visible(second_bar)
	health_bar.get("theme_override_styles/fill").set("bg_color", color)
