extends Control

@onready var pseudo_line = $Home/Pseudo
@onready var home_tab = $Home
@onready var role_select_tab = $RoleSelect
@onready var shop_tab = $Shop

var dragging_window := false
var drag_start_position : Vector2i

func _ready():
	home_tab.show()
	shop_tab.hide()
	role_select_tab.hide()
	
	#multiplayer.connected_to_server.connect(_on_connected_ok)
	#multiplayer.connection_failed.connect(_on_connected_fail)
	#multiplayer.server_disconnected.connect(_on_server_disconnected)
	#Replication.enter_role_select.connect(_enter_role_select)
	#Replication.enter_game_loading.connect(_enter_game_loading)
	#
	#start_client()
#
#func start_client() -> void:
	#ClientManager.set_state(Basics.ClientState.ENTERED)
	#var peer = ENetMultiplayerPeer.new()
	#var error = peer.create_client(Replication.DEFAULT_SERVER_IP, Replication.PORT)
	#if error:
		#logger.error(str("Error creating client : ", error))
		#return
	#logger.info("Client created.")
	#multiplayer.multiplayer_peer = peer
#
#func _on_connected_ok():
	#logger.info("connection established.")
	#send_player_infos(pseudo_line.text)
#
#func _on_connected_fail():
	#logger.error(str("connection failed for peer : ", multiplayer.multiplayer_peer))
	#multiplayer.multiplayer_peer = null
#
#func _on_server_disconnected():
	#logger.warning("server disconnected.")
	#multiplayer.multiplayer_peer = null

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
	Replication.launch_role_select.rpc()
	_enter_role_select()

func _enter_role_select() -> void:
	role_select_tab.show()
	home_tab.hide()
	shop_tab.hide()

func _on_lock_in_pressed() -> void:
	Replication.lock_role.rpc(multiplayer.get_unique_id(), Basics.Role.HUNTER)
	_enter_game_loading()

func _enter_game_loading() -> void:
	get_tree().change_scene_to_file("res://Scenes/loading.tscn")

func _on_drag_bar_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == 1:
		if !dragging_window:
			drag_start_position = get_viewport().get_mouse_position()
		dragging_window = event.is_pressed()

func _process(_delta: float) -> void:
	if dragging_window:
		var _mouse_delta := Vector2i(get_viewport().get_mouse_position()) - drag_start_position
		get_window().position += _mouse_delta
