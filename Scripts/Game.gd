extends Node3D

const MAP_SIZE := Vector2(200.0, 200.0)
const CAMP_DISTANCE_TO_CENTER = 70.0
var bases_position : PackedVector2Array
var pre_base = preload("res://Scenes/Props/Camp.tscn")
var pre_player = preload("res://Scenes/Player.tscn")
var pre_tree = preload("res://Scenes/Models/TreeModel.tscn")
var pre_plant = preload("res://Scenes/Props/Plant.tscn")

var koka_plant = preload("res://Ressources/Plants/KokaPlant.tres")
var players : Array[Object]

@onready var multi_tree = $MultiTrees
@onready var ground_body = $NavMesh/GroundBody
@onready var navmesh = $NavMesh

func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	map_generation()
	spawn_player(get_node("NavMesh/Camp/PlayerSpawn/1").global_position, get_node("NavMesh/Camp/PlayerSpawn").global_position)
	send_map_data_to_player(paths_points_list, bases_position, interest_points_list)

func map_generation() -> void:
	var _random_vector = Vector2(0, CAMP_DISTANCE_TO_CENTER).rotated(randf_range(-PI, PI))
	bases_position.append_array([_random_vector, _random_vector.rotated(PI)])
	randomize()
	generate_bases(bases_position)
	generate_paths(MAP_SIZE)
	generate_mid()
	generate_forest(MAP_SIZE, bases_position[0], bases_position[1])
	generate_plant_and_camps()

func generate_bases(pos : Array[Vector2]) -> void:
	for p in pos:
		var _new_base = pre_base.instantiate()
		_new_base.position = Vector3(p.x, 0, p.y)
		navmesh.add_child(_new_base)
		_new_base.look_at(Vector3())

var mid_points_list = PackedVector2Array()
func generate_mid() -> void:
	for i in range(50):
		mid_points_list.append(bases_position[0] + bases_position[0].direction_to(bases_position[1]) * bases_position[0].distance_to(bases_position[1])/50.0*i)

#var _box = CSGBox3D.new()
#_box.position = Vector3(0, 0, 0)
#add_child(_box)

var interest_points_list = PackedVector2Array()
var paths_points_list : Array[PackedVector2Array]
const PATH_RANDOM_CELLS = 0.4
const PATH_MIN_POINTS = 5
const PATH_MAX_POINTS = 10
const POINT_PRECISION = 4.0
const MAX_VECTOR_ANGLE = 1
const NO_PATH_BORDER_LENGTH = 30.0
const CHANCE_TO_SPAWN_PLANT = 0.1
func generate_paths(map_size : Vector2) -> void:
	for x in range(map_size.x/18):
		for y in range(map_size.y/18):
			var _vector_direction = Vector2(randf()-0.5, randf()-0.5).normalized()
			var _vector_pos = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*18.0 - Vector2(map_size)/2
			
			if is_close_to_square_border(map_size, _vector_pos + map_size/2.0, NO_PATH_BORDER_LENGTH):
				continue
			
			var _temp_point_list = PackedVector2Array()
			var _path_length = randi_range(PATH_MIN_POINTS, PATH_MAX_POINTS)
			for i in range(_path_length):
				if !is_tree_in_camp(_vector_pos, bases_position[0], bases_position[1]) and !is_tree_in_mid(_vector_pos):
					if randf() < CHANCE_TO_SPAWN_PLANT:
						interest_points_list.append(_vector_pos)
					elif i+1 == _path_length:
						interest_points_list.append(_vector_pos)
				_temp_point_list.append(_vector_pos)
				_vector_pos += _vector_direction * POINT_PRECISION
				_vector_direction = _vector_direction.rotated(randf_range(-MAX_VECTOR_ANGLE, MAX_VECTOR_ANGLE)) 
			
			paths_points_list.append(_temp_point_list)

func send_map_data_to_player(paths_list : Array[PackedVector2Array], bases_list : PackedVector2Array, plants_list : PackedVector2Array):
	for p in players:
		p.update_mini_map_points(paths_list, bases_list, plants_list)

func is_close_to_square_border(square_size : Vector2, detection_point : Vector2, detection_length : float) -> bool:
	if detection_point.x > square_size.x - detection_length or detection_point.x < detection_length or detection_point.y > square_size.y - detection_length or detection_point.y < detection_length:
		return true
	return false

const DIVISION_FACTOR := 1.5
const TREE_RANDOM_CELLS = 0.4
const TREE_BORDER_LENGTH := 16.0
const NO_TREE_CAMP_DISTANCE := 15.0
const NO_TREE_PATH_DISTANCE := 3.0
const NO_TREE_MID_DISTANCE := 5.0
const TREE_ROTATION_MAX = PI/6.0
const TREE_SCALE_MIN = 0.1
const TREE_SCALE_MAX = 0.2
func generate_forest(map_size : Vector2i, base1_pos : Vector2, base2_pos : Vector2) -> void:
	var tree_count = 0
	
	for x in range(int(map_size.x/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
		for y in range(int(map_size.y/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
			var _new_position = DIVISION_FACTOR*Vector2(x + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS), y + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS)) - Vector2(map_size)/2 - Vector2(TREE_BORDER_LENGTH, TREE_BORDER_LENGTH)
			
			if is_tree_in_camp(_new_position, base1_pos, base2_pos) or is_tree_in_path(_new_position) or is_tree_in_mid(_new_position):
				continue
			
			var _basis_vec = Vector3(randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0).normalized()
			var _basis = Basis(_basis_vec, randf_range(-TREE_ROTATION_MAX, TREE_ROTATION_MAX))
			var _transform = Transform3D(_basis * randf_range(TREE_SCALE_MIN, TREE_SCALE_MAX), Vector3(_new_position.x, 0, _new_position.y))
			multi_tree.multimesh.set_instance_transform(tree_count, _transform)
			
			add_collision_cube(_new_position)
			
			tree_count += 1
	multi_tree.multimesh.visible_instance_count = tree_count
	navmesh.bake_navigation_mesh()

func add_collision_cube(pos : Vector2) -> void:
	var _new_collision_cube = CollisionShape3D.new()
	_new_collision_cube.shape = BoxShape3D.new()
	_new_collision_cube.shape.size = Vector3(2.0, 4.0, 2.0)
	_new_collision_cube.position = Vector3(pos.x, 1.5, pos.y)
	ground_body.add_child(_new_collision_cube)

func generate_plant_and_camps() -> void:
	for i in interest_points_list:
		var _new_plant = pre_plant.instantiate()
		_new_plant.position = Vector3(i.x, 0, i.y)
		_new_plant.rotate(Vector3.UP, randf_range(-PI, PI))
		_new_plant.plant = koka_plant
		add_child(_new_plant)

func is_tree_in_camp(pos : Vector2, camp1_pos : Vector2, camp2_pos : Vector2) -> bool:
	if pos.distance_to(camp1_pos) < NO_TREE_CAMP_DISTANCE or pos.distance_to(camp2_pos) < NO_TREE_CAMP_DISTANCE:
		return true
	return false

func is_tree_in_path(pos : Vector2) -> bool:
	for paths in paths_points_list:
		for points in paths:
			if pos.distance_to(points) < NO_TREE_PATH_DISTANCE:
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
	players.append(_new_player)
