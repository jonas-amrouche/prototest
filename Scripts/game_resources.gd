extends Node

## Items are loaded once at startup and cached here.
## All other systems read from this list — never scan the filesystem mid-game.
var all_items : Array[Item] = []

func _ready() -> void:
	all_items = Basics.load_all_items()

var cursors = [preload("res://Assets/2D/UI/cursor_normal.png"), preload("res://Assets/2D/UI/cursor_attack.png"), preload("res://Assets/2D/UI/cursor_loot.png")]

var move_effect = preload("res://Scenes/UI/click_move_effect.tscn")
var item_ground = preload("res://Scenes/Systems/item_ground.tscn")
var dead_color_correction = preload("res://Resources/ColorCorection/DeadColorCorrection.tres")

var item_hud = preload("res://Scenes/UI/item_hud.tscn")
var ability_hud = preload("res://Scenes/UI/ability_hud.tscn")
var item_craft = preload("res://Scenes/UI/item_craft.tscn")
var stat_hud = preload("res://Scenes/UI/stat_hud.tscn")
var effect_hud = preload("res://Scenes/UI/effect_hud.tscn")
var item_preview = preload("res://Scenes/UI/item_preview.tscn")
var ability_preview = preload("res://Scenes/UI/ability_preview.tscn")
var effect_preview = preload("res://Scenes/UI/effect_preview.tscn")

var outer_wall_entity = preload("res://Resources/Entities/outer_wall.tres")
var monster_entity = preload("res://Resources/Entities/monster.tres")
var player_entity = preload("res://Resources/Entities/player.tres")

var decorations_models = [preload("res://Scenes/Models/tribal_sanctuary_round_model.tscn"), \
preload("res://Scenes/Models/tribal_stone_square_model.tscn"), \
preload("res://Scenes/Decorations/altar.tscn")]

var monster_scene = preload("res://Scenes/monster.tscn")
var player_scene = preload("res://Scenes/player.tscn")
var base_structure = preload("res://Scenes/Structures/base.tscn")
var arena_structure = preload("res://Scenes/Structures/water_arena.tscn")
var camp_structure = preload("res://Scenes/Structures/camp.tscn")
var tower_structure = preload("res://Scenes/Structures/knowledge_tower.tscn")

var camps_list = [preload("res://Resources/Camps/OmniscientGolem.tres"), \
preload("res://Resources/Camps/Gobedins.tres"), \
preload("res://Resources/Camps/DispossessedWillow.tres"), \
preload("res://Resources/Camps/Grunters.tres"), \
preload("res://Resources/Camps/LostGhosts.tres")]
