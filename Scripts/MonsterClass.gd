extends Resource
class_name Monster

@export var id : String
@export var name : String
@export var monster_scene : PackedScene
@export var drop_components : Array[Component]
@export var drop_quantities : PackedInt32Array
@export var respawn_time : float
