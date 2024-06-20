extends PanelContainer

@export var item : Item

func _ready():
	$MarginIcon/Icon.texture = item.icon
