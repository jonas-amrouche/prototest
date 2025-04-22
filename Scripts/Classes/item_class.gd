class_name Item
extends Resource

@export var id : String
@export var name : String
@export_multiline var description : String
@export var icon : Texture2D
@export var rarity : Basics.RARITY
@export var mesh_model : PackedScene
@export var craft_recipe : Dictionary
@export var abilities : Array[Ability]
@export var passives : Array[Passive]
@export var stats : Dictionary
