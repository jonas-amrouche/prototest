extends PanelContainer

@export var icon : Texture2D
@export var stat : String

func _ready():
	$MarginCont/StatIcon.texture = icon
	$MarginCont/StatLabel.text = stat
