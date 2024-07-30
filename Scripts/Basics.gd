extends Node

enum RARITY {STARTER, ORDINARY, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL}
const RARITY_TEXT = ["Starter", "Ordinary", "Elite", "Fantastic", "Legendary", "Mythical", "Theoretical"]
const RARITY_COLORS = [Color(0.659, 0.584, 0.561), Color(0.36, 0.56, 0.252), Color(0.322, 0.553, 0.698), Color(0.957, 0.882, 0.184), Color(0.506, 0.255, 0.686), Color(0.537, 0, 0.016), Color(0.62, 0.804, 0.561)]
enum ABILITY_ERROR {OK, IN_COOLDOWN, UNAVAILABLE}

const DAMAGE_COLOR = [Color(0.813, 0.134, 0.182), Color(0.4, 0.317, 0.813), Color(0.4, 0.317, 0.813)]

var stats_data := {"physical_damage" : preload("res://Ressources/Stats/PhysicalDamage.tres"), \
"magic_damage" : preload("res://Ressources/Stats/MagicDamage.tres"), \
"physical_armor" : preload("res://Ressources/Stats/PhysicalArmor.tres"), \
"magic_armor" : preload("res://Ressources/Stats/MagicArmor.tres"), \
"movement_speed" : preload("res://Ressources/Stats/MovementSpeed.tres"), \
"cooldown_reduction" : preload("res://Ressources/Stats/CooldownReduction.tres"), \
"health_regeneration" : preload("res://Ressources/Stats/HealthRegeneration.tres"), \
"max_health" : preload("res://Ressources/Stats/MaxHealth.tres"), \
"life_steal" : preload("res://Ressources/Stats/LifeSteal.tres")}
