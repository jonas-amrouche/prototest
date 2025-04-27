extends Resource
class_name Ability

## ID for script functions only
@export var id : String
## Description displayed in-game
@export_multiline var description : String
## Icon displayed in-game
@export var icon : Texture2D
## Spell range for targeted spells and auto attack trigger of other spells
@export var spell_range : float
## If the spell is targeted
@export var targeted : bool
## Cooldown when ability is finished
@export var cooldown : float
## Total life of the ability
@export var life_time : float
## Time before calling the main action, can be different from channeling time because of an animation
@export var action_time : float
## If the spell has a channeling time, channeling time is action_time
@export var channeling : bool
@export var damage_type : int
@export var damage_cap : int
## If the spell is a toggle speel
@export var toggle : bool
## If the spell is a charge based speel
@export var charging : bool
## Base charges
@export var charges : int = 0
var slot_id : int = -1
