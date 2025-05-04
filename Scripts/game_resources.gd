extends Node

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

var cursors = [preload("res://Assets/2D/UI/cursor_normal.png"), preload("res://Assets/2D/UI/cursor_attack.png"), preload("res://Assets/2D/UI/cursor_loot.png")]

var recall_ability = preload("res://Resources/Abilities/recall.tres")

var dead_color_correction = preload("res://Resources/ColorCorection/DeadColorCorrection.tres")

var decorations_models = [preload("res://Scenes/Models/tribal_sanctuary_round_model.tscn"), \
preload("res://Scenes/Models/tribal_stone_square_model.tscn"), \
preload("res://Scenes/Decorations/altar.tscn")]

var pre_base = preload("res://Scenes/Structures/base.tscn")
var pre_player = preload("res://Scenes/player.tscn")
var pre_arena = preload("res://Scenes/Structures/water_arena.tscn")
var pre_camp = preload("res://Scenes/Structures/camp.tscn")
var pre_tower = preload("res://Scenes/Structures/knowledge_tower.tscn")

var pre_camps = [preload("res://Resources/Camps/OmniscientGolem.tres"), \
preload("res://Resources/Camps/Gobedins.tres"), \
preload("res://Resources/Camps/DispossessedWillow.tres"), \
preload("res://Resources/Camps/Grunters.tres"), \
preload("res://Resources/Camps/LostGhosts.tres")]
