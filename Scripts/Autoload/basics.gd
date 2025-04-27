extends Node

const MAP_SIZE = Vector2(150.0, 150.0)
enum RARITY {COMPONENTS, STARTER, ORDINARY, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL}
const RARITY_TEXT = ["Components", "Starter", "Ordinary", "Elite", "Fantastic", "Legendary", "Mythical", "Theoretical"]
#const RARITY_COLORS = [Color(0.627, 0.322, 0.176), Color(0.659, 0.584, 0.561), Color(0.36, 0.56, 0.252), Color(0.322, 0.553, 0.698), Color(0.957, 0.882, 0.184), Color(0.506, 0.255, 0.686), Color(0.537, 0, 0.016), Color(0.62, 0.804, 0.561)]

const STATS_COLOR = {"magic_damage" : Color.SLATE_BLUE, "physical_damage" : Color.FIREBRICK, "magic_armor" : Color.DARK_SLATE_BLUE, "physical_armor" : Color.BROWN}
enum ABILITY_ERROR {OK, IN_COOLDOWN, NO_TARGET, OUT_OF_RANGE, UNAVAILABLE, NEED_RESOURCE, SCRIPT_ERROR}
enum ABILITY_CANCEL {MOVING, TAKING_DAMAGE}
enum ABILITY_VICTIM {TARGET, AREA, GROUP, LOGIC}
const DAMAGE_COLOR = [Color.FIREBRICK, Color.SLATE_BLUE]

enum CURSOR_MODE {NORMAL, ATTACK, LOOT}
var cursors = [preload("res://Assets/2D/UI/cursor_normal.png"), preload("res://Assets/2D/UI/cursor_attack.png"), preload("res://Assets/2D/UI/cursor_loot.png")]

var stats_data := {"physical_damage" : preload("res://Resources/Stats/PhysicalDamage.tres"), \
"magic_damage" : preload("res://Resources/Stats/MagicDamage.tres"), \
"physical_armor" : preload("res://Resources/Stats/PhysicalArmor.tres"), \
"magic_armor" : preload("res://Resources/Stats/MagicArmor.tres"), \
"movement_speed" : preload("res://Resources/Stats/MovementSpeed.tres"), \
"cooldown_reduction" : preload("res://Resources/Stats/CooldownReduction.tres"), \
"health_regeneration" : preload("res://Resources/Stats/HealthRegeneration.tres"), \
"max_health" : preload("res://Resources/Stats/MaxHealth.tres"), \
"life_steal" : preload("res://Resources/Stats/LifeSteal.tres"), \
"souls" : preload("res://Resources/Stats/Souls.tres")}

var decorations_models = [preload("res://Scenes/Models/tribal_sanctuary_round_model.tscn"), \
preload("res://Scenes/Models/tribal_stone_square_model.tscn"), \
preload("res://Scenes/Decorations/altar.tscn")]
