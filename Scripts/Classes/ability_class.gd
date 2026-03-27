class_name Ability
extends Resource

@export var id           : StringName
@export var display_name : String
@export_multiline var description : String
@export var icon         : Texture2D

@export var ability_type : Basics.AbilityType = Basics.AbilityType.TARGETED

@export var action_time  : float = 0.0
@export var channeling   : bool  = false
@export var life_time    : float = 0.0  ## 0 = instant cleanup
@export var cooldown     : float = 1.0
@export var charges      : int   = 0   ## 0 = single cooldown, no charges

@export var spell_range  : float = 0.0  ## 0 = unlimited
@export var targeted     : bool  = false

@export var damage_type  : Basics.DamageType = Basics.DamageType.PHYSICAL
@export var damage_scale : float = 1.0
@export var damage_cap   : int   = 0  ## 0 = no cap

@export var area_radius      : float = 0.0
@export var projectile_speed : float = 0.0  ## 0 = instant

@export var on_hit_effects : Array[Effect] = []

## True = targets auto_attack_target. Used for auto-attacks and monster abilities.
@export var targets_auto : bool = false

var slot_id : int = -1  ## -1 = unbound, 0–11 = bar slot index
