extends Node

const MAP_SIZE = Vector2(150.0, 150.0)
enum Rarity {CLASSIC, RARE, ELITE, FANTASTIC, LEGENDARY, MYTHICAL, THEORETICAL}
const RARITY_TEXT = ["classic", "rare", "elite", "fantastic", "legendary", "mythical", "theoretical"]
const RARITY_COLORS = [Color(0, 0, 0),\
 Color(0, 0.275, 0),\
 Color(0, 0.162, 0.27),\
 Color(0.27, 0.153, 0),\
 Color(0.27, 0.27, 0),\
 Color(0.27, 0.009, 0.0),\
 Color(0.27, 0.27, 0.27)]

enum ClientState {DISCONNECTED, ENTERED, LOADING, INGAME}

enum ItemType {ITEM, COMPONENTS, CONSUMABLE}
enum SlotType {INVENTORY, CRAFT, CONSUMABLE}

const STATS_COLOR = {"magic_damage" : Color.SLATE_BLUE, "physical_damage" : Color.FIREBRICK, "magic_armor" : Color.DARK_SLATE_BLUE, "physical_armor" : Color.BROWN, "movement_speed" : Color.DARK_SLATE_BLUE, "max_health" : Color.DARK_GREEN}
enum AbilityError {OK, IN_COOLDOWN, NO_TARGET, OUT_OF_RANGE, UNAVAILABLE, NEED_RESOURCE, SCRIPT_ERROR}
enum AbilityCancel {MOVING, TAKING_DAMAGE}
enum AbilityVictim {TARGET, AREA, GROUP, LOGIC}
enum DamageType {PHYSIC, MAGIC, HYBRID}
const DAMAGE_COLOR = [Color.FIREBRICK, Color.SLATE_BLUE]

enum EntityType {PLAYER, MONSTER, NPCS, ITEM, GUARDS, STRUCTURE}

const CRAFT_TIME = 2.0

enum Class {HUNTER, SWORDSMAN, DOCTOR, DRUID, HEALER, HEAVY_FIGHTER, ASSASSIN}
const CLASS_TEXT = ["hunter", "swordsman", "doctor", "druid", "healer", "heavy_fighter", "assassin"]

enum CursorMode {NORMAL, ATTACK, LOOT}

func get_all_items() -> Array[Item]:
	var _item_base: Array[Item] = []
	var _path : String = "res://Resources/Items/"
	var _dir = DirAccess.open(str(_path))
	_dir.list_dir_begin()
	var _file_name = _dir.get_next()
	while _file_name != "":
		var _file_path = str(_path) + "/" + _file_name
		if !_dir.current_is_dir():
			_item_base.append(load(_file_path))
		_file_name = _dir.get_next()
	return _item_base

func get_all_stats() -> Dictionary[String, Stat]:
	var _stat_base: Dictionary[String, Stat]
	var _path : String = "res://Resources/Stats/"
	var _dir = DirAccess.open(str(_path))
	_dir.list_dir_begin()
	var _file_name = _dir.get_next()
	while _file_name != "":
		var _file_path = str(_path) + "/" + _file_name
		if !_dir.current_is_dir():
			var _stat = load(_file_path)
			_stat_base[_stat.id] = _stat
		_file_name = _dir.get_next()
	return _stat_base
