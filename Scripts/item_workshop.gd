extends PanelContainer

@export var item : Item
var available := true
signal update_item_preview()
signal mouse_entered_item(itm : Item)

@onready var hud = get_parent().get_parent().get_parent().get_parent()
@onready var icon = $Pad/IconPad/ItemIcon
@onready var name_label = $Pad/DataPad/ItemData/ItemName
@onready var desc_label = $Pad/DataPad/ItemData/DescLine
#@onready var black_cont = $BlackCont
#@onready var rarity_filter = $BorderMargin/RarityFilter
@onready var rarity_overlay = $Pad/IconPad/RarityOverlay
#@onready var consumable_overlay = $BorderMargin/ConsumableOverlay
@onready var select_pan = $SelectPad/Select
@onready var unavailable_pan = $UnavailablePad/Unavailable
@onready var comps_container = $Pad/DataPad/ItemData/CompsList

var pre_item_hud = preload("res://Scenes/UI/item_hud.tscn")

func _ready():
	update_slot()

func update_slot() -> void:
	if item:
		icon.texture = item.entity.icon
		name_label.text = item.entity.id.capitalize()
		desc_label.text = item.description
		var _color = Basics.RARITY_COLORS[item.rarity]
		_color *= 0.4
		#rarity_filter.get_theme_stylebox("panel").set("bg_color", _color)
		rarity_overlay.set_texture(load("res://Assets/2D/UI/item_overlay_" + Basics.RARITY_TEXT[item.rarity] + ".png"))
		
		for comps in comps_container.get_children():
			comps.queue_free()
		
		for item_craft in item.craft:
			var _new_item_hud = pre_item_hud.instantiate()
			var _new_item_slot = ItemSlot.new()
			_new_item_slot.quantity = 1
			_new_item_slot.item = item_craft
			_new_item_slot.slot_id = -1
			_new_item_hud.item_slot = _new_item_slot
			_new_item_hud.connect("mouse_entered_item", Callable(hud, "show_item_preview"))
			_new_item_hud.connect("mouse_exited", Callable(hud, "hide_item_preview"))
			_new_item_hud.custom_minimum_size = Vector2(30.0, 30.0)
			comps_container.add_child(_new_item_hud)
	else:
		icon.texture = null
	#if item:
		#match item.type:
			#Basics.ItemType.CONSUMABLE:
				#consumable_overlay.show()
	if !available:
		unavailable_pan.show()

func _on_gui_input(event):
	if event is InputEventMouseButton:
		update_item_preview.emit()

func _on_mouse_entered():
	if !available: return
	select_pan.show()
	mouse_entered_item.emit(item)

func _on_mouse_exited() -> void:
	select_pan.hide()
