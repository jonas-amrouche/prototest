extends PanelContainer

@export var item : Item
signal select_item(item_selected : Item)

func _ready():
	$MarginIcon/Icon.texture = item.icon

func _on_select_button_down():
	select_item.emit(item)
