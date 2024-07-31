extends PanelContainer

@export var item : Item
signal select_item(item_selected : Item)
signal mouse_entered_item(itm : Item)

func _ready():
	$MarginIcon/Icon.texture = item.icon

func _on_select_button_down():
	select_item.emit(item)

func _on_mouse_entered():
	mouse_entered_item.emit(item)
