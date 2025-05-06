extends Control

@onready var ally_cards = $AllyCards
@onready var ennemy_cards = $EnnemyCards

var player_loading_card_scene = preload("res://Scenes/UI/player_loading_card.tscn")

func _ready() -> void:
	for p in range(Replication.players.size()):
		var _new_card = player_loading_card_scene.instantiate()
		_new_card.player_infos = Replication.players.values()[p]
		ally_cards.add_child(_new_card)
	
	await get_tree().create_timer(5.0).timeout
	
	get_tree().change_scene_to_file("res://Scenes/game.tscn")
