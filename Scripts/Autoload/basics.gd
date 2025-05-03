extends Node

const MAP_SIZE = Vector2(150.0, 150.0)
enum RARITY {CLASSIC, RARE, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL}
const RARITY_TEXT = ["classic", "rare", "elite", "fantastic", "legendary", "mythical", "theoretical"]
const RARITY_COLORS = [Color(0, 0, 0),\
 Color(0, 0.275, 0),\
 Color(0, 0.162, 0.27),\
 Color(0.27, 0.153, 0),\
 Color(0.27, 0.27, 0),\
 Color(0.27, 0.009, 0.0),\
 Color(0.27, 0.27, 0.27)]

enum ITEM_TYPE {ITEM, COMPONENTS, CONSUMABLE}
enum SLOT_TYPE {INVENTORY, CRAFT, CONSUMABLE}

const STATS_COLOR = {"magic_damage" : Color.SLATE_BLUE, "physical_damage" : Color.FIREBRICK, "magic_armor" : Color.DARK_SLATE_BLUE, "physical_armor" : Color.BROWN, "movement_speed" : Color.DARK_SLATE_BLUE}
enum ABILITY_ERROR {OK, IN_COOLDOWN, NO_TARGET, OUT_OF_RANGE, UNAVAILABLE, NEED_RESOURCE, SCRIPT_ERROR}
enum ABILITY_CANCEL {MOVING, TAKING_DAMAGE}
enum ABILITY_VICTIM {TARGET, AREA, GROUP, LOGIC}
enum DAMAGE_TYPE {PHYSIC, MAGIC}
const DAMAGE_COLOR = [Color.FIREBRICK, Color.SLATE_BLUE]

enum ENTITY_TYPE {PLAYER, MONSTER}

const CRAFT_TIME = 2.0

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

var recall_ability = preload("res://Resources/Abilities/recall.tres")

var dead_color_correction = preload("res://Resources/ColorCorection/DeadColorCorrection.tres")

var decorations_models = [preload("res://Scenes/Models/tribal_sanctuary_round_model.tscn"), \
preload("res://Scenes/Models/tribal_stone_square_model.tscn"), \
preload("res://Scenes/Decorations/altar.tscn")]

func get_all_items() -> Array[Item]:
	var _item_base: Array[Item] = []
	var _path = "res://Resources/Items/"
	var _dir = DirAccess.open(_path)
	_dir.list_dir_begin()
	var _file_name = _dir.get_next()
	while _file_name != "":
		var _file_path = _path + "/" + _file_name
		if !_dir.current_is_dir():
			_item_base.append(load(_file_path))
		_file_name = _dir.get_next()
	return _item_base
