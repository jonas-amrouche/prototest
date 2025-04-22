extends PanelContainer

@export var item : Item
signal drag_item(slot : Object)
signal drop_item(slot : Object)
signal update_item_preview()
signal mouse_entered_item(itm : Item)

@onready var icon = $RarityCont/BlackCont/Icon
@onready var rarity_pan = $RarityCont/Rarity
@onready var rarity_cont = $RarityCont

func _ready():
	update_slot()

func update_slot() -> void:
	if item:
		icon.texture = item.icon
		rarity_pan.get("theme_override_styles/panel").set("bg_color", Basics.RARITY_COLORS[item.rarity])
	else:
		icon.texture = null

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_item.emit(self)
			mouse_entered_item.emit(item)

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if item:
				grabbed = true
				rarity_cont.z_index = 1
				drag_item.emit(self)
				mouse_exited.emit()
		else:
			rarity_cont.z_index = 0
			rarity_cont.position = Vector2(2.0, 2.0)
			grabbed = false
	if event is InputEventMouseMotion:
		if grabbed:
			rarity_cont.position = get_viewport().get_mouse_position() - global_position - size/2.0
		else:
			update_item_preview.emit()

func _on_mouse_entered():
	if !grabbed:
		mouse_entered_item.emit(item)
