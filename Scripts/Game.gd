extends Node3D

const MAP_SIZE := Vector2(200.0, 200.0)
var pre_camp = preload("res://Scenes/Props/Camp.tscn")
var pre_player = preload("res://Scenes/Player.tscn")
var pre_tree = preload("res://Scenes/Models/TreeModel.tscn")

func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	map_generation()
	spawn_player(get_node("Camp/PlayerSpawn/1").global_position, get_node("Camp/PlayerSpawn").global_position)

const CAMP_POSITION = [Vector2(-70, 70), Vector2(70, -70)]
func map_generation() -> void:
	randomize()
	generate_camp(CAMP_POSITION[0], Vector3(1.0, 1.0, 1.0))
	generate_camp(CAMP_POSITION[1], Vector3(-1.0, 1.0, -1.0))
	generate_paths(MAP_SIZE)
	generate_mid(MAP_SIZE)
	generate_forest(MAP_SIZE, CAMP_POSITION[0], CAMP_POSITION[1])

func generate_camp(pos : Vector2, scl : Vector3) -> void:
	var _new_camp = pre_camp.instantiate()
	_new_camp.position = Vector3(pos.x, 0, pos.y)
	_new_camp.scale = scl
	add_child(_new_camp)

var mid_points_list = PackedVector2Array()
func generate_mid(map_size : Vector2) -> void:
	for i in range(50):
		mid_points_list.append(Vector2(-map_size.x, map_size.y)/2.0 + Vector2(map_size.x/50.0 * i, -map_size.y/50.0 * i))

var paths_points_list = PackedVector2Array()
const POINT_PRECISION = 4.0
const MAX_VECTOR_ANGLE = 1
func generate_paths(map_size : Vector2) -> void:
	for x in range(map_size.x/18):
		for y in range(map_size.y/18):
			var _vector_direction = Vector2(randf()-0.5, randf()-0.5).normalized()
			var _vector_pos = Vector2(x + randf_range(-0.4, 0.4), y + randf_range(-0.4, 0.4))*18.0 - Vector2(map_size)/2
			for i in range(randi_range(5, 10)):
				paths_points_list.append(_vector_pos)
				#var _box = CSGBox3D.new()
				#_box.position = Vector3(_vector_pos.x, 0, _vector_pos.y)
				#add_child(_box)
				_vector_pos += _vector_direction * POINT_PRECISION
				_vector_direction = _vector_direction.rotated(randf_range(-MAX_VECTOR_ANGLE, MAX_VECTOR_ANGLE)) 

func generate_polygons(map_size : Vector2, cell_division : float, camp1_pos : Vector2, camp2_pos : Vector2):
	for x in range(int(map_size.x/cell_division)):
		for y in range(int(map_size.y/cell_division)):
			var _new_position = Vector2(x+0.5 + randf_range(-0.4, 0.4), y+0.5 + randf_range(-0.4, 0.4))*cell_division - map_size/2
			if _new_position.distance_to(camp1_pos) < NO_TREE_CAMP_DISTANCE or _new_position.distance_to(camp2_pos) < NO_TREE_CAMP_DISTANCE:
				continue
			var _new_polygon = CSGPolygon3D.new()
			_new_polygon.depth = 3.0
			_new_polygon.rotate(Vector3.RIGHT, PI/2.0)
			var _points = PackedVector2Array()
			var _circle_division = randi_range(5, 11)
			var _last_point_length = 1.0
			for p in range(_circle_division):
				var _new_length = lerp(_last_point_length, randf_range(1, _circle_division), 0.75)
				_points.append(Vector2(0, lerp(_last_point_length, _new_length, randf_range(0.35, 0.65))).rotated(PI*2.0/_circle_division*p-(PI*2.0/_circle_division/2.0)))
				_points.append(Vector2(0, _new_length).rotated((PI*2.0)/_circle_division*p))
				_last_point_length = _new_length
			
			_new_polygon.position = Vector3(_new_position.x, 0, _new_position.y)
			_new_polygon.polygon = _points
			add_child(_new_polygon)

const NO_TREE_CAMP_DISTANCE := 15.0
const NO_TREE_PATH_DISTANCE := 4.0
const NO_TREE_MID_DISTANCE := 6.0
func generate_forest(map_size : Vector2i, camp1_pos : Vector2, camp2_pos : Vector2) -> void:
	for x in range(map_size.x):
		for y in range(map_size.y):
			var _new_position = Vector2(x + randf_range(-0.4, 0.4), y + randf_range(-0.4, 0.4)) - Vector2(map_size)/2
			if is_tree_in_camp(_new_position, camp1_pos, camp2_pos) or is_tree_in_path(_new_position) or is_tree_in_mid(_new_position):
				continue
			var _new_tree = pre_tree.instantiate()
			_new_tree.position = Vector3(_new_position.x, 0, _new_position.y)
			add_child(_new_tree)

func is_tree_in_camp(pos : Vector2, camp1_pos : Vector2, camp2_pos : Vector2) -> bool:
	if pos.distance_to(camp1_pos) < NO_TREE_CAMP_DISTANCE or pos.distance_to(camp2_pos) < NO_TREE_CAMP_DISTANCE:
		return true
	return false

func is_tree_in_path(pos : Vector2) -> bool:
	for p in paths_points_list:
		if pos.distance_to(p) < NO_TREE_PATH_DISTANCE:
			return true
	return false

func is_tree_in_mid(pos : Vector2) -> bool:
	for p in mid_points_list:
		if pos.distance_to(p) < NO_TREE_MID_DISTANCE:
			return true
	return false
	

func spawn_player(pos : Vector3, center_spawn : Vector3) -> void:
	var _new_player = pre_player.instantiate()
	_new_player.position = pos
	_new_player.target_direction = pos.direction_to(center_spawn)
	add_child(_new_player)
