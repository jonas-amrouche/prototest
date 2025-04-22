extends Node3D

@onready var anim = $AnimationPlayer

func _ready() -> void:
	anim.play("dissapear")
	get_tree().create_timer(0.5).timeout.connect(func():
		queue_free())
