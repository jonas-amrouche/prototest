extends Node3D

var tree_skin := 0

func _ready():
	get_node("Tree" + str(tree_skin+1))

