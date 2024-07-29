extends PanelContainer

var component : Component

@onready var comp_name = $Pad/ComponentName

func _ready():
	comp_name.text = component.name
