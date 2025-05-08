extends Node

@onready var client_logger : ClientLogger = $CanvasLayer/ClientLogger

var state : Basics.ClientState = Basics.ClientState.DISCONNECTED

func set_state(sta: Basics.ClientState) -> void:
	state = sta

func _ready() -> void:
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	Replication.load_finished.connect(_load_finished)
	start_client()

func load_game() -> void:
	client_logger.info("Loading game scene.")
	var _game_scene = load("res://Scenes/game.tscn")
	add_child(_game_scene.instantiate(), true)
	Replication.rpc("player_loaded", multiplayer.get_unique_id())

func start_client() -> void:
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(Replication.DEFAULT_SERVER_IP, Replication.PORT)
	if error:
		client_logger.error(str("Error creating client : ", error))
		return
	client_logger.info("Client created.")
	multiplayer.multiplayer_peer = peer

func _on_connected_ok():
	client_logger.info("Connection established.")
	set_state(Basics.ClientState.INGAME)
	Replication.update_player_infos.rpc(multiplayer.get_unique_id(), Replication.client_infos)
	load_game()

func _on_connected_fail():
	client_logger.error(str("Connection failed for peer : ", multiplayer.multiplayer_peer))
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	client_logger.warning("Server disconnected.")
	multiplayer.multiplayer_peer = null

func _load_finished():
	pass
