extends Resource
class_name Entity

@export var id : String
@export var entity_type : Basics.EntityType
@export var icon : Texture2D
@export var max_health : int
var health : int
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
## Allows taking multiple potion without getting potion sickness
@export var potion_resistence : int

signal state_changed

func set_full_health() -> void:
	set_health(max_health)
	state_changed.emit()

func set_id(name : String):
	id = name
	state_changed.emit()

func set_entity_type(et : Basics.EntityType):
	entity_type = et
	state_changed.emit()

func set_icon(ic : Texture2D):
	icon = ic
	state_changed.emit()

func set_max_health(mh : int):
	max_health = mh
	state_changed.emit()

func set_health(hp : int):
	health = hp
	state_changed.emit()

func set_health_regeneration(hr : int):
	health_regeneration = hr
	state_changed.emit()

func set_physical_damage(pd : int):
	physical_damage = pd
	state_changed.emit()

func set_physical_armor(pa : int):
	physical_armor = pa
	state_changed.emit()

func set_magic_damage(md : int):
	magic_damage = md
	state_changed.emit()

func set_magic_armor(ma : int):
	magic_armor = ma
	state_changed.emit()

func set_movement_speed(ms : int):
	movement_speed = ms
	state_changed.emit()

func set_cooldown_reduction(cr : int):
	cooldown_reduction = cr
	state_changed.emit()

func set_life_steal(ls : int):
	life_steal = ls
	state_changed.emit()

func set_souls(s : int):
	souls = s
	state_changed.emit()

func set_integrity(i : int):
	integrity = i
	state_changed.emit()

func set_robustness(r : int):
	robustness = r
	state_changed.emit()

func set_focus(f : int):
	focus = f
	state_changed.emit()

func set_spirit(sp : int):
	spirit = sp
	state_changed.emit()

func set_soul_division(sd : int):
	soul_division = sd
	state_changed.emit()
