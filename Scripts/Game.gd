extends Node3D

@onready var resources = $GameResources
@onready var beacons = $Beacons
@onready var camps = $Camps
@onready var monsters = $Monsters
@onready var items = $Items
@onready var temp_vision = $TempVision
@onready var env = $WorldEnvironment.environment
@onready var map_generation = $MapGeneration

var generated_data : Dictionary

func _ready() -> void:
	add_to_group("world")
	if OS.is_debug_build():
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(Vector2i(1280, 720))

@rpc("any_peer", "reliable")
func launch_game() -> void:
	if multiplayer.is_server():
		map_generation.generate_map()
		spawn_players()

@rpc("any_peer", "reliable", "call_remote")
func send_map_data_to_player(data : Dictionary):
	generated_data = data
	#print(Replication.players)
	#print_rich(("[color=red]server" if multiplayer.is_server() else "[color=blue]client"), "[/color] : ", multiplayer.get_unique_id())
	#for p in Replication.players.values():
		#p.vision.initialize_fog_map(bases_list)
		#p["player_ref"].hud.init_map_data(generated_data)
		#p.hud.init_map_data(paths_list, bases_list, interests_list, camps_list)
	map_generation.spawn_map(generated_data)

func set_color_correction(grad : GradientTexture1D) -> void:
	env.set_adjustment_color_correction(grad)

func vision_update(vision : Object, _fog_map : Image) -> void:
	for m in map_generation.monsters.get_children():
		m.set_visible(vision.has_vision(Vector2i(m.global_position.x, m.global_position.z)))
	
	for c in map_generation.items.get_children():
		c.set_visible(vision.has_vision(Vector2i(c.global_position.x, c.global_position.z)))
	
	for c in map_generation.camps.get_children():
		c.change_camp_visibility(vision.has_vision(Vector2i(c.global_position.x, c.global_position.z)))

func spawn_players() -> void:
	#var _new_player = resources.player_scene.instantiate()
	#_new_player.position = map_generation.bases[0].get_node("PlayerSpawn/1").global_position
	#_new_player.name = str(Replication.players.keys()[0])
	#add_child(_new_player, true)
	for i in range(Replication.players.size()):
		var _new_player = resources.player_scene.instantiate()
		_new_player.position = map_generation.bases[0].get_node("PlayerSpawn/" + str(i+1)).global_position
		_new_player.name = str(Replication.players.keys()[i])
		add_child(_new_player, true)
		Replication.players[Replication.players.keys()[i]]["player_ref"] = _new_player

var spawn_count = 0
func _on_multiplayer_spawner_spawned(node: Node) -> void:
	node.position = map_generation.bases[0].get_node("PlayerSpawn/" + str(spawn_count+1)).global_position
	spawn_count += 1
