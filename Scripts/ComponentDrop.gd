extends Node3D

var component : Component
var quantity : int

func _on_pick_up_body_shape_entered(_body_rid, body, _body_shape_index, _local_shape_index):
	body.obtain_component(component, quantity)
	queue_free()
