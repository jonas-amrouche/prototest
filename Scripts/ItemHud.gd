extends PanelContainer

@export var item : Item
signal drag_drop_item(item_dropped : Item)

@onready var icon = $MarginIcon/Icon

func _ready():
	update_slot()

func update_slot() -> void:
	if item:
		icon.texture = item.icon
		get("theme_override_styles/panel").set("bg_color", Basics.RARITY_COLORS[item.rarity])

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				grabbed = true
				icon.z_index = 1
			else:
				grabbed = false
				icon.z_index = 0
				var _grab_pos = get_viewport().get_mouse_position()
				var _invetory_area = Rect2(get_node("..").global_position.x, get_node("..").global_position.y, get_node("..").size.x, get_node("..").size.y)
				if _grab_pos.x > _invetory_area.position.x and _grab_pos.x < _invetory_area.end.x and _grab_pos.y > _invetory_area.position.y and _grab_pos.y < _invetory_area.end.y:
					icon.position = Vector2(2, 2)
				else:
					drag_drop_item.emit(item)
	if event is InputEventMouseMotion and grabbed:
		icon.position = get_viewport().get_mouse_position() - global_position - size/2.0
