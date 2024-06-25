extends PanelContainer

@export var item : Item
signal drag_drop_item(item_dropped : Item)

func _ready():
	$MarginIcon/Icon.texture = item.icon

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				grabbed = true
			else:
				grabbed = false
				var _grab_pos = position + size/2.0
				if _grab_pos.x > 0.0 and _grab_pos.x < get_node("..").size.x and _grab_pos.y > 0.0 and _grab_pos.y < get_node("..").size.y:
					position = Vector2()
				else:
					drag_drop_item.emit(item)
	if event is InputEventMouseMotion and grabbed:
		position = get_viewport().get_mouse_position() - get_node("..").global_position - size/2.0
