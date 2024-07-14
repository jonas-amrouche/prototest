class_name Item
extends Resource

enum CLASS {STARTER, ORDINARY, ELITE, FANTASTIC, LEGENDARY, MYTHIC, THEORETICAL}

@export var id : String
@export var name : String
@export_multiline var description : String
@export var icon : Texture2D
@export var rarity : CLASS
@export var mesh_model : PackedScene
@export var craft_recipe : Dictionary
@export var abilities : Array[Ability]
@export var physical_damage : int
@export var magic_damage : int
@export var physical_armor : int
@export var magic_armor : int
@export var movement_speed : float
@export var cooldown_reduction : float
@export var health_regeneration : float
@export var strength_regeneration : float
@export var max_health : int
@export var max_strength : int
@export var life_steal : float
