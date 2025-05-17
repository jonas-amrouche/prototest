extends Node

@onready var client_logger : ClientLogger = $CanvasLayer/ClientLogger

var state : Basics.ClientState = Basics.ClientState.DISCONNECTED

var game_scene : String = "res://Scenes/game.tscn"

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
	#var _game_scene = load("res://Scenes/game.tscn")
	ResourceLoader.load_threaded_request(game_scene)
	set_state(Basics.ClientState.LOADING)

func _process(_delta: float) -> void:
	if state == Basics.ClientState.LOADING:
		check_load_progress()

func check_load_progress() -> void:
	# INFO : load progress can be retrieved with "load_threaded_get_status" if we want
	var _load_status = ResourceLoader.load_threaded_get_status(game_scene) 
	if _load_status == ResourceLoader.THREAD_LOAD_LOADED:
		var _loaded_scene = ResourceLoader.load_threaded_get(game_scene)
		add_child(_loaded_scene.instantiate(), true)
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
	Replication.update_player_infos.rpc_id(1, multiplayer.get_unique_id(), Replication.client_infos)
	load_game()

func _on_connected_fail():
	client_logger.error(str("Connection failed for peer : ", multiplayer.multiplayer_peer))
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	client_logger.warning("Server disconnected.")
	multiplayer.multiplayer_peer = null

func _load_finished():
	client_logger.info("Scene loaded, entering game.")
	set_state(Basics.ClientState.INGAME)
