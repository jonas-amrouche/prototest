extends PanelContainer

@export var item : Item

@onready var icon_item_1 = $Item1
@onready var icon_item_2 = $Item2
@onready var icon_item_3 = $Item3

func _ready():
	update_recipe()

func update_recipe() -> void:
	if item:
		icon_item_1.texture = item.craft_1.icon_resting
		icon_item_2.texture = item.craft_2.icon_resting
		icon_item_3.texture = item.icon_resting
