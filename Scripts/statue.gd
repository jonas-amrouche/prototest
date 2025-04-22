extends Node3D

@onready var alran_model = $AlranModel
@onready var eyna_model = $EynaModel

var statue_id := 0

func _ready() -> void:
	match statue_id:
		0:
			alran_model.show()
			eyna_model.hide()
		1:
			eyna_model.show()
			alran_model.hide()
