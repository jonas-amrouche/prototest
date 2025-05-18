extends PanelContainer

@export var item_slot : ItemSlot
@export var available := true
@export var keybind : String
signal drag_item(slot : Object)
signal drop_item(slot : Object)
signal update_item_preview()
signal mouse_entered_item(itm : Item)
signal show_abilities(itm : Item, itm_ref : Object)

@onready var icon = $DragCont/Icon
@onready var drag_cont = $DragCont
@onready var black_cont = $BlackCont
@onready var rarity_filter = $BorderMargin/RarityFilter
@onready var rarity_overlay = $BorderMargin/RarityOverlay
@onready var consumable_overlay = $BorderMargin/ConsumableOverlay
@onready var component_overlay = $BorderMargin/ComponentOverlay
@onready var select_pan = $Select
@onready var unavailable_pan = $Unavailable
@onready var keybind_label = $KeybindPad/Keybind
@onready var quantity_lab = $DragCont/QuantityCont/Quantity

func _ready():
	update_slot()

func update_slot() -> void:
	if item_slot and item_slot.item:
		icon.texture = item_slot.item.entity.icon
		match item_slot.item.type:
			Basics.ItemType.COMPONENTS:
				component_overlay.show()
		quantity_lab.set_visible(item_slot.quantity > 1)
		quantity_lab.text = str(item_slot.quantity)
		var _color = Basics.RARITY_COLORS[item_slot.item.rarity]
		_color *= 0.4
		rarity_filter.get_theme_stylebox("panel").set("bg_color", _color)
		#black_cont.get_theme_stylebox("panel").set("bg_color", Basics.RARITY_COLORS[item_slot.item.rarity])
		rarity_overlay.set_texture(load("res://Assets/2D/UI/item_overlay_" + Basics.RARITY_TEXT[item_slot.item.rarity] + ".png"))
	else:
		icon.texture = null
	if item_slot:
		match item_slot.slot_type:
			Basics.SlotType.CONSUMABLE:
				keybind_label.set_text(keybind.replace("(Physical)", ""))
				consumable_overlay.show()
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
var press_item = false
func _on_gui_input(event):
	if !available: return
	if event is InputEventMouseButton and event.button_index == 1:
		if event.pressed:
			if item_slot:
				grabbed = true
				drag_cont.z_index = 1
				drag_item.emit(self)
				mouse_exited.emit()
		else:
			drag_cont.z_index = 0
			drag_cont.position = Vector2(2.0, 2.0)
			grabbed = false
	if event is InputEventMouseButton and event.button_index == 2:
		if event.pressed:
			press_item = true
		elif press_item:
			press_item = false
			if item_slot.item and item_slot.item.abilities.size() > 0:
				show_abilities.emit(item_slot.item, self)
	if event is InputEventMouseMotion:
		if grabbed:
			drag_cont.position = get_viewport().get_mouse_position() - global_position - size/2.0
		else:
			update_item_preview.emit()

func _on_mouse_entered():
	if !available: return
	select_pan.show()
	if !grabbed and item_slot:
		mouse_entered_item.emit(item_slot.item)

func _on_mouse_exited() -> void:
	select_pan.hide()
