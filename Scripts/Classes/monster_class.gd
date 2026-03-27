class_name Monster
extends Resource

@export var display_name    : String
@export var entity          : Entity
@export var monster_model   : PackedScene
@export var item_drops      : Array[ItemDrop]
@export var experience_drop : int   = 100
@export var abilities       : Array[Ability]
@export var aggro           : bool  = false
@export var aggro_range     : float = 4.0
@export var roam            : bool  = false
@export var roam_range      : float = 5.0
@export var turn_speed      : float = 0.04
