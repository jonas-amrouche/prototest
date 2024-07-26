extends Node3D

func _on_craft_area_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	body.entering_base()

func _on_craft_area_body_shape_exited(_body_rid, body, _body_shape_index, _local_shape_index):
	body.exit_base()
