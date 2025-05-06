extends Control

@onready var logger : ClientLogger = $Logger
@onready var pseudo_line = $Pseudo

const PORT = 7000
const DEFAULT_SERVER_IP = "localhost" # IPv4 localhost

var player_info = {}

func _ready():
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	
	start_client()

func start_client() -> void:
	ClientManager.set_state(Basics.ClientState.ENTERED)
	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(DEFAULT_SERVER_IP, PORT)
	if error:
		logger.error(str("Error creating client : ", error))
		return
	logger.info("Client created.")
	multiplayer.multiplayer_peer = peer

func _on_connected_ok():
	logger.info("connection established.")
	send_player_infos(pseudo_line.text)

func _on_connected_fail():
	logger.error(str("connection failed for peer : ", multiplayer.multiplayer_peer))
	multiplayer.multiplayer_peer = null

func _on_server_disconnected():
	logger.warning("server disconnected.")
	multiplayer.multiplayer_peer = null
	#players.clear()
	#server_disconnected.emit()

func _on_close_pressed():
	get_tree().quit()

func _on_minimize_pressed(): 
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)

func _on_pseudo_text_changed(new_text: String) -> void:
	send_player_infos(new_text)

func send_player_infos(pseudo : String) -> void:
	Replication.client_infos["name"] = pseudo
	Replication.update_player_info.rpc(multiplayer.get_unique_id(), Replication.client_infos)

func _on_enter_game_pressed() -> void:
	pass # Replace with function body.
