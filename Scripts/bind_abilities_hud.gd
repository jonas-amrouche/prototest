extends PanelContainer

var item : Item

var hud
@onready var abilities_cont = $Pad/AbilitiesList

var ability_hud_scene = preload("res://Scenes/UI/ability_hud.tscn")

func _ready() -> void:
	update_abilities()

func update_abilities() -> void:
	for ab in abilities_cont.get_children():
		ab.queue_free()
	
	for ability in item.abilities:
		var _new_ability_hud = ability_hud_scene.instantiate()
		_new_ability_hud.ability = ability
		_new_ability_hud.item = item
		if hud:
			_new_ability_hud.connect("drag_ability", Callable(hud, "drag_ability"))
			_new_ability_hud.connect("drop_ability", Callable(hud, "drop_ability"))
			_new_ability_hud.connect("mouse_entered_ability", Callable(hud, "show_ability_preview"))
			_new_ability_hud.connect("mouse_exited", Callable(hud, "hide_ability_preview"))
		abilities_cont.add_child(_new_ability_hud)
