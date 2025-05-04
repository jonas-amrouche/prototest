class_name Item
extends Resource

@export var id : String
@export_multiline var description : String
@export var icon : Texture2D
@export var type : Basics.ItemType
@export var rarity : Basics.Rarity
@export var mesh_model : PackedScene
@export var craft_1 : Item
@export var craft_2 : Item
@export var abilities : Array[Ability]
@export var passives : Array[Passive]
@export var stats : Dictionary
