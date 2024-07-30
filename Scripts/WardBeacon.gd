extends Node3D

func _on_destroy_timeout():
	queue_free()
