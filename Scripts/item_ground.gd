extends Node3D

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

func _on_pick_up_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	#body.obtain_item(item, quantity)
	#queue_free()
	pass
