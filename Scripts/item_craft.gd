extends PanelContainer

@export var item : Item
signal select_item(item_selected : Item)
signal mouse_entered_item(itm : Item)

func _ready() -> void:
	$MarginIcon/Icon.texture = item.icon

func _on_select_button_down() -> void:
	select_item.emit(item)
	get_theme_stylebox("panel").set("bg_color", Color(0.23, 0.23, 0.23))

func unselect_item() -> void:
	get_theme_stylebox("panel").set("bg_color", Color(0.1, 0.1, 0.1))

func _on_mouse_entered() -> void:
	mouse_entered_item.emit(item)
