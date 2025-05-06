extends Area3D

var entity_type = Basics.EntityType.ITEM

signal state_changed

var item : Item
var quantity : int

@onready var icon_tex := $IconTex
@onready var icon_tex_shadow := $IconTexShadow

func _ready() -> void:
	var _rand_rot = randf_range(-PI, PI)
	if item:
		icon_tex.set_texture(item.icon)
		icon_tex_shadow.set_texture(item.icon)
		icon_tex.rotate(Vector3.UP, _rand_rot)
		icon_tex_shadow.rotate(Vector3.UP, _rand_rot)
		icon_tex.position.y = randf_range(-0.64, -0.66)

func loot_item() -> void:
	queue_free()

func hover_target() -> void:
	state_changed.emit()
	icon_tex.set_layer_mask_value(14, true)
	icon_tex_shadow.set_layer_mask_value(14, true)

func stop_hovering_target() -> void:
	icon_tex.set_layer_mask_value(14, false)
	icon_tex_shadow.set_layer_mask_value(14, false)

func select_target() -> void:
	icon_tex.set_layer_mask_value(14, false)
	icon_tex_shadow.set_layer_mask_value(14, false)
	icon_tex.set_layer_mask_value(15, true)
	icon_tex_shadow.set_layer_mask_value(15, true)

func lose_target() -> void:
	icon_tex.set_layer_mask_value(15, false)
	icon_tex_shadow.set_layer_mask_value(15, false)
