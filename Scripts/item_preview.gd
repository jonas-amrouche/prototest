extends PanelContainer

var item : Item

@onready var item_icon = $Pad/Pad/ItemIcon
@onready var rarity_label = $Pad/ItemData/Rarity
@onready var item_name = $Pad/ItemData/ItemName
@onready var desc_line = $Pad/ItemData/DescLine
@onready var stats_container = $Pad/ItemData/Specs/StatsBox
@onready var abilities_container = $Pad/ItemData/Specs/AbilitiesBox
@onready var passives_container = $Pad/ItemData/Specs/PassiveBox
@onready var rarity_icon = $Pad/Pad/Rarity
@onready var spec_spacer = $Pad/ItemData/DataSpecsSep
@onready var spec_container = $Pad/ItemData/Specs

var pre_ability_preview = preload("res://Scenes/UI/ability_preview.tscn")
var pre_passive_preview = preload("res://Scenes/UI/passive_item_preview.tscn")

func _ready():
	update_content()

func update_content() -> void:
	if item:
		item_icon.set_texture(item.icon)
		rarity_icon.set_texture(load("res://Assets/2D/UI/item_overlay_" + Basics.RARITY_TEXT[item.rarity] + ".png"))
		rarity_label.set_text("R : " + Basics.RARITY_TEXT[item.rarity].capitalize())
		#rarity_label.label_settings.set("font_color", Basics.RARITY_COLORS[item.rarity])
		item_name.set_text(item.id.capitalize())
		desc_line.set_text(item.description)
		
		clear_stats()
		for s in range(item.stats.size()):
			add_stat(item.stats.values()[s], Basics.stats_data[item.stats.keys()[s]])
			
		clear_abilities()
		if item.type != Basics.ITEM_TYPE.CONSUMABLE:
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

var stat_font = preload("res://Assets/Fonts/Gamaliel.otf")
func add_stat(stat_value : int, stat : Stat) -> void:
	var _new_stat = Label.new()
	var _new_lab_settings = LabelSettings.new()
	_new_lab_settings.font_color = Basics.STATS_COLOR[stat.id]
	_new_lab_settings.font_size = 14
	_new_lab_settings.font = stat_font
	_new_stat.label_settings = _new_lab_settings
	_new_stat.set_text("+" + str(stat_value) + " " + stat.name)
	stats_container.show()
	spec_spacer.show()
	spec_container.show()
	stats_container.add_child(_new_stat)

func add_ability(ablty : Ability) -> void:
	var _new_ability = pre_ability_preview.instantiate()
	_new_ability.ability = ablty
	_new_ability.item = item
	abilities_container.show()
	spec_spacer.show()
	spec_container.show()
	abilities_container.add_child(_new_ability)

func add_passive(pasv : Passive) -> void:
	var _new_passive = pre_passive_preview.instantiate()
	_new_passive.passive = pasv
	passives_container.show()
	spec_spacer.show()
	spec_container.show()
	passives_container.add_child(_new_passive)
