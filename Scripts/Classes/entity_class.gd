extends Resource
class_name Entity

@export var id : String
@export var entity_type : Basics.EntityType
@export var icon : Texture2D
@export var max_health : int = 100
var health : int = max_health
@export var health_regeneration : int
@export var physical_damage : int
@export var physical_armor : int
@export var magic_damage : int
@export var magic_armor : int
#@export var dark_magic : int
#@export var light_magic : int
#@export var free_magic : int
#@export var rune_magic : int
#@export var light_crit : int
#@export var dark_steal : int
## Movement speed of the entity
@export var movement_speed : int 
## Reduction of cooldown of all abilities
@export var cooldown_reduction : int 
## Life recover from dealing damage
@export var life_steal : int 
## Souls taken (kills), dormant stats if not used by any items
var souls : int 
## Nerf critical hits and lifesteal taken
@export var integrity : int 
## Nerf slows and stuns taken
@export var robustness : int 
## Nerf slows and stuns taken
@export var focus : int 
## Reduce cost of mana of all abilities by a percentange
@export var spirit : int 
## Allows multi-casting, percentage of left channel ability time where you can cast another ability
@export var soul_division : int 
