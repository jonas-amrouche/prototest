extends PanelContainer

@export var component : Component
@export var quantity : int

func _ready():
	$MarginIcon/Icon.texture = component.icon
	$MarginQuantity/Quantity.text = str(quantity)
