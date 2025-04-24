extends PanelContainer

@export var item_slot : ItemSlot
signal drag_item(slot : Object)
signal drop_item(slot : Object)
signal update_item_preview()
signal mouse_entered_item(itm : Item)

@onready var icon = $ItemCont/BlackCont/Icon
@onready var rarity_pan = $ItemCont/Rarity
@onready var quantity_lab = $QuantityCont/Quantity
@onready var item_cont = $ItemCont/BlackCont/Icon

func _ready():
	update_slot()

func update_slot() -> void:
	if item_slot:
		icon.texture = item_slot.item.icon
		quantity_lab.set_visible(item_slot.quantity > 1)
		quantity_lab.text = str(item_slot.quantity)
		rarity_pan.get("theme_override_styles/panel").set("bg_color", Basics.RARITY_COLORS[item_slot.item.rarity])
	else:
		icon.texture = null

func _unhandled_input(event):
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_item.emit(self)
			if item_slot:
				mouse_entered_item.emit(item_slot.item)

var grabbed = false
func _on_gui_input(event):
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if item_slot:
				grabbed = true
				item_cont.z_index = 1
				drag_item.emit(self)
				mouse_exited.emit()
		else:
			item_cont.z_index = 0
			item_cont.position = Vector2(2.0, 2.0)
			grabbed = false
	if event is InputEventMouseMotion:
		if grabbed:
			item_cont.position = get_viewport().get_mouse_position() - global_position - size/2.0
		else:
			update_item_preview.emit()

func _on_mouse_entered():
	if !grabbed and item_slot:
		mouse_entered_item.emit(item_slot.item)
