extends Resource
class_name Monster

@export var id : String
@export var name : String
@export var monster_model : PackedScene
@export var drop_components : Array[Component]
@export var drop_quantities : PackedInt32Array
@export var experience_drop : int = 1
@export var abilities : Array[Ability]
@export var aggro : bool
@export var aggro_range : float = 4.0
@export var roam : bool
@export var roam_range : float = 5.0
@export var turn_speed : float = 0.04
@export var max_health : int = 100
@export var physical_damage : int
@export var magic_damage : int
@export var physical_armor : int
@export var magic_armor : int
@export var movement_speed : float = 1.5
@export var health_regeneration : float = 2.0
