extends Resource
class_name Plant

@export var id : String
@export var name : String
@export var mesh_model : PackedScene
@export var vanish_on_take : bool
@export var harvest_time : float
@export var harvest_components : Array[Component]
@export var harvest_quantities : PackedInt32Array
@export var grow_time : float
