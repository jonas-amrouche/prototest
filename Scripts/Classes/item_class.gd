class_name Item
extends Resource

@export var entity : Entity
@export_multiline var description : String
@export var type : Basics.ItemType
@export var rarity : Basics.Rarity
@export var mesh_model : PackedScene
@export var craft : Array[Item]
@export var abilities : Array[Ability]
@export var passives : Array[Passive]
