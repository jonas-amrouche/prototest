extends PanelContainer

var item : Item

@onready var item_icon = $MarginContainer/ItemIcon
@onready var rarity_label = $MarginContainer/ItemData/Rarity
@onready var item_name = $MarginContainer/ItemData/ItemName
@onready var desc_line = $MarginContainer/ItemData/DescLine
@onready var stats_container = $MarginContainer/ItemData/Specs/StatsBox
@onready var abilities_container = $MarginContainer/ItemData/Specs/AbilitiesBox
@onready var passives_container = $MarginContainer/ItemData/Specs/PassiveBox

var pre_ability_preview = preload("res://Scenes/UI/AbilityPreview.tscn")
var pre_passive_preview = preload("res://Scenes/UI/PassiveItemPreview.tscn")

func _ready():
	update_content()

func update_content() -> void:
	if item:
		item_icon.set_texture(item.icon)
		rarity_label.set_text(Basics.RARITY_TEXT[item.rarity])
		item_name.label_settings.set("font_color", Basics.RARITY_COLORS[item.rarity])
		item_name.set_text(item.name)
		desc_line.set_text(item.description)
		
		clear_stats()
		for s in range(item.stats.size()):
			add_stat(item.stats.values()[s], Basics.stats_data[item.stats.keys()[s]])
			
		clear_abilities()
		for a in item.abilities:
			add_ability(a)
			
		clear_passives()
		for p in item.passives:
			add_passive(p)
		
		call_deferred("show")

func clear_stats() -> void:
	for i in stats_container.get_children():
		i.queue_free()

func clear_abilities() -> void:
	for i in abilities_container.get_children():
		i.queue_free()

func clear_passives() -> void:
	for i in passives_container.get_children():
		i.queue_free()

var stat_font = preload("res://Assets/Fonts/Stilu-Regular.otf")
func add_stat(stat_value : int, stat : Stat) -> void:
	var _new_stat = Label.new()
	var _new_lab_settings = LabelSettings.new()
	_new_lab_settings.font_color = Basics.STATS_COLOR[stat.id]
	_new_lab_settings.font_size = 13
	_new_lab_settings.font = stat_font
	_new_stat.label_settings = _new_lab_settings
	_new_stat.set_text("+" + str(stat_value) + " " + stat.name)
	stats_container.add_child(_new_stat)

func add_ability(ablty : Ability) -> void:
	var _new_ability = pre_ability_preview.instantiate()
	_new_ability.ability = ablty
	abilities_container.add_child(_new_ability)

func add_passive(pasv : Passive) -> void:
	var _new_passive = pre_passive_preview.instantiate()
	_new_passive.passive = pasv
	passives_container.add_child(_new_passive)
