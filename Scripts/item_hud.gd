extends PanelContainer

@export var item_slot : ItemSlot
@export var available := true
signal drag_item(slot : Object)
signal drop_item(slot : Object)
signal update_item_preview()
signal mouse_entered_item(itm : Item)

@onready var icon = $ItemCont/Icon
@onready var black_cont = $ItemCont/BlackCont
@onready var boder_overlay = $BorderMargin/BorderOverlay
@onready var select_pan = $Select
@onready var unavailable_pan = $Unavailable
@onready var quantity_lab = $QuantityCont/Quantity
@onready var item_cont = $ItemCont/Icon

func _ready():
	update_slot()

func update_slot() -> void:
	if item_slot:
		icon.texture = item_slot.item.icon
		quantity_lab.set_visible(item_slot.quantity > 1)
		quantity_lab.text = str(item_slot.quantity)
		
		if item_slot.item.rarity == Basics.RARITY.COMPONENTS:
			black_cont.get("theme_override_styles/panel").set("bg_color", Color(0.0, 0.1, 0.0, 0.918))
		if item_slot.item.consumable:
			boder_overlay.show()
	else:
		icon.texture = null
	
	if !available:
		unavailable_pan.show()

func _unhandled_input(event):
	if !available: return
	if event is InputEventMouseButton and event.button_index == 1 and !event.pressed:
		var _mouse_pos = get_viewport().get_mouse_position()
		var _trigger = Rect2(global_position, size)
		if _mouse_pos.x > _trigger.position.x and _mouse_pos.x < _trigger.end.x and _mouse_pos.y > _trigger.position.y and _mouse_pos.y < _trigger.end.y:
			drop_item.emit(self)
			if item_slot:
				mouse_entered_item.emit(item_slot.item)

var grabbed = false
func _on_gui_input(event):
	if !available: return
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
	if !available: return
	select_pan.show()
	if !grabbed and item_slot:
		mouse_entered_item.emit(item_slot.item)

func _on_mouse_exited() -> void:
	select_pan.hide()
