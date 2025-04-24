extends Resource
class_name Ability

## ID for script functions only
@export var id : String
## Name displayed in-game
@export var name : String
## Description displayed in-game
@export_multiline var description : String
## Icon displayed in-game
@export var icon : Texture2D
## Cooldown when ability is finished
@export var cooldown : float
## Total life of the ability
@export var life_time : float
## Time before calling the main action, can be different from channeling time because of an animation
@export var action_time : float
@export var channeling : bool
@export var damage_type : int
@export var damage_cap : int
