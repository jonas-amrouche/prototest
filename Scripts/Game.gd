extends Node3D

const MAP_SIZE := Vector2(200.0, 200.0)
const CAMP_DISTANCE_TO_CENTER = 70.0
var bases_position : PackedVector2Array
var pre_base = preload("res://Scenes/Props/Base.tscn")
var pre_player = preload("res://Scenes/Player.tscn")
var pre_arena = preload("res://Scenes/Models/MidArenaModel.tscn")
var pre_plant = preload("res://Scenes/Props/Plant.tscn")
var decorations = [preload("res://Scenes/Models/TribalPillarTorchModel.tscn"), preload("res://Scenes/Models/TribalSanctuaryRoundModel.tscn"), preload("res://Scenes/Models/TribalStoneSquareModel.tscn")]

var plants = [preload("res://Ressources/Plants/KokaPlant.tres")]
var players : Array[Object]

@onready var multi_tree = $MultiTrees
@onready var ground_body = $NavMesh/GroundBody
@onready var navmesh = $NavMesh

func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	map_generation()
	spawn_player(get_node("NavMesh/Base/PlayerSpawn/1").global_position, get_node("NavMesh/Base/PlayerSpawn").global_position)
	send_map_data_to_player(paths_points_list, bases_position, interest_points_list)

func map_generation() -> void:
	randomize()
	generate_bases()
	generate_points_and_paths()
	generate_mid_arena()
	generate_decoration()
	#mirror_points()
	#generate_collisions()
	generate_forest()
	generate_interests_camps()

func generate_bases() -> void:
	var _random_vector = Vector2(0, CAMP_DISTANCE_TO_CENTER).rotated(randf_range(-PI, PI))
	bases_position.append_array([_random_vector, _random_vector.rotated(PI)])
	
	for b in bases_position:
		var _new_base = pre_base.instantiate()
		_new_base.position = Vector3(b.x, 0.0, b.y)
		navmesh.add_child(_new_base)
		_new_base.look_at(Vector3())

var interest_points_list = PackedVector2Array()
var paths_points_list : Array[PackedVector2Array]
const POINT_CELL_DIVISION = 22
const PATH_RANDOM_CELLS = 0.4
const PATH_MIN_POINTS = 5
const PATH_MAX_POINTS = 10
const POINT_PRECISION = 4.0
const MAX_VECTOR_ANGLE = 1
const NO_PATH_BORDER_LENGTH = 20.0
const CHANCE_TO_SPAWN_PLANT = 0.05

const PATH_RESOLUTION = 1.0
const SIN_DIVISION = 3.0
const SIN_FORCE = 2.0
const ARENA_PATH_MULTIPLIER = 0.2
func generate_points_and_paths() -> void:
	# Generate arena and base interest points for path (Deleted at the end)
	interest_points_list.append(Vector2(0.0, 0.0))
	for base in bases_position:
		interest_points_list.append(base)
	
	# Generate interest points
	for x in range(MAP_SIZE.x/POINT_CELL_DIVISION):
		for y in range(MAP_SIZE.y/POINT_CELL_DIVISION):
			var _new_point = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*float(POINT_CELL_DIVISION) - Vector2(MAP_SIZE)/2
			if is_close_to_square_border(MAP_SIZE, _new_point + MAP_SIZE/2.0, NO_PATH_BORDER_LENGTH):
				continue
			interest_points_list.append(_new_point)
	
	# Generate path between interest points
	for p in interest_points_list:
		var _point_linked = PackedVector2Array()
		var _path_number = 4 if p == Vector2() else randi_range(1, 4)
		for path in range(_path_number):
			var _closest_point = Vector2(1000.0, 1000.0)
			for cp in interest_points_list:
				if p.distance_to(cp) < p.distance_to(_closest_point) and p != cp and !_point_linked.has(cp):
					_closest_point = cp
			_point_linked.append(_closest_point)
			
			var _temp_point_list = PackedVector2Array()
			for i in range(int(p.distance_to(_closest_point)/PATH_RESOLUTION)):
				var _point_pos = (_closest_point-p)/p.distance_to(_closest_point)/PATH_RESOLUTION * i
				_point_pos += cos(_point_pos.length()/SIN_DIVISION) * p.direction_to(_closest_point).rotated(PI/2.0) * SIN_FORCE
				#print(_point_pos)
				_temp_point_list.append(p + _point_pos)
				#debug_box(Vector3(p.x + _point_pos.x, 0.0, p.y + _point_pos.y), 1.0)
			paths_points_list.append(_temp_point_list)
	
	#Comme on genere sur une grid on devrait être cacpable de trouver les 4 points autour du milieu auquel rattach
	# Generate path between arena and probably linked to base paths
	
	
	# Clear interest points in bases and arena
	var _removed_value = 0
	for p in range(interest_points_list.size()):
		if is_in_base(interest_points_list[p - _removed_value]) or is_in_arena(interest_points_list[p - _removed_value]):
			interest_points_list.remove_at(p - _removed_value)
			_removed_value += 1

const ARENA_SIZE = 10.0
func generate_mid_arena() -> void:
	var _new_arena = pre_arena.instantiate()
	_new_arena.position = Vector3(0.0, 0.0, 0.0)
	add_child(_new_arena)

#func generate_points_and_paths() -> void:
	#for x in range(MAP_SIZE.x/POINT_CELL_DIVISION):
		#for y in range(MAP_SIZE.y/POINT_CELL_DIVISION):
			#var _vector_direction = Vector2(randf()-0.5, randf()-0.5).normalized()
			#var _vector_pos = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*float(POINT_CELL_DIVISION) - Vector2(MAP_SIZE)/2
			#
			#if is_close_to_square_border(MAP_SIZE, _vector_pos + MAP_SIZE/2.0, NO_PATH_BORDER_LENGTH):
				#continue
			#
			#var _temp_point_list = PackedVector2Array()
			#var _path_length = randi_range(PATH_MIN_POINTS, PATH_MAX_POINTS)
			#for i in range(_path_length):
				#if !is_in_base(_vector_pos) and !is_in_mid(_vector_pos):
					#if randf() < CHANCE_TO_SPAWN_PLANT:
						#interest_points_list.append(_vector_pos)
					#elif i+1 == _path_length:
						#interest_points_list.append(_vector_pos)
				#_temp_point_list.append(_vector_pos)
				#_vector_pos += _vector_direction * POINT_PRECISION
				#_vector_direction = _vector_direction.rotated(randf_range(-MAX_VECTOR_ANGLE, MAX_VECTOR_ANGLE)) 
			#paths_points_list.append(_temp_point_list)

func debug_box(pos : Vector3, size : float = 1.0, color : Color = Color(1.0, 1.0, 1.0)) -> void:
	var _box = CSGBox3D.new()
	_box.position = pos
	_box.scale *= size
	_box.material = StandardMaterial3D.new()
	_box.material.albedo_color = color
	add_child(_box)

func mirror_points() -> void:
	var _removed_paths_count := 0
	for p in range(paths_points_list.size()):
		var _removed_point_count := 0
		for point in range(paths_points_list[p - _removed_paths_count].size()):
			if is_on_right_side(paths_points_list[p - _removed_paths_count][point - _removed_point_count]):
				paths_points_list[p - _removed_paths_count].remove_at(point - _removed_point_count)
				_removed_point_count += 1
		if paths_points_list[p - _removed_paths_count].is_empty():
			paths_points_list.remove_at(p - _removed_paths_count)
			_removed_paths_count += 1
	
	var _removed_interest_count := 0
	for i in range(interest_points_list.size()):
		if is_on_right_side(interest_points_list[i - _removed_interest_count]):
			interest_points_list.remove_at(i - _removed_interest_count)
			_removed_interest_count += 1
	
	var _new_miror_paths = paths_points_list.duplicate(true)
	for pa in range(_new_miror_paths.size()):
		for po in range(_new_miror_paths[pa].size()):
			_new_miror_paths[pa].set(po, _new_miror_paths[pa][po] * -1.0)
	paths_points_list.append_array(_new_miror_paths)
	
	for i in range(interest_points_list.size()):
		interest_points_list.append(interest_points_list[i] * -1.0)

func is_on_right_side(point : Vector2) -> bool:
	if (bases_position[1].x - bases_position[0].x)*(point.y - bases_position[0].y)-(point.x - bases_position[0].x)*(bases_position[1].y - bases_position[0].y) > 0:
		return true
	return false

#const WALL_DISPLACEMENT := 1.3
#func generate_collisions() -> void:
	#for path in paths_points_list:
		#for p in range(path.size()):
			#var _displace_vec = path[p].direction_to(path[p+1]).rotated(PI/2.0) * DISPLACEMENT_TO_CENTER if p+1 < path.size() else path[p-1].direction_to(path[p]) * DISPLACEMENT_TO_CENTER
			#var _left_position = path[p] + _displace_vec * WALL_DISPLACEMENT
			#if is_in_base(_left_position) or is_in_mid(_left_position) or is_in_path(_left_position):
				#continue
			#add_collision_cube(_left_position, _displace_vec*-1.0)
			#var _right_position = path[p] + _displace_vec * -1.0 * WALL_DISPLACEMENT
			#if is_in_base(_right_position) or is_in_mid(_right_position) or is_in_path(_right_position):
				#continue
			#add_collision_cube(_right_position, _displace_vec)

func send_map_data_to_player(paths_list : Array[PackedVector2Array], bases_list : PackedVector2Array, interests_list : PackedVector2Array):
	for p in players:
		p.update_map_data(paths_list, bases_list, interests_list)

func is_close_to_square_border(square_size : Vector2, detection_point : Vector2, detection_length : float) -> bool:
	if detection_point.x > square_size.x - detection_length or detection_point.x < detection_length or detection_point.y > square_size.y - detection_length or detection_point.y < detection_length:
		return true
	return false

const DIVISION_FACTOR := 1.5
const TREE_RANDOM_CELLS = 0.4
const TREE_BORDER_LENGTH := 16.0
const NO_TREE_CAMP_DISTANCE := 15.0
const NO_TREE_PATH_DISTANCE := 2.5
const TREE_ROTATION_MAX = PI/6.0
const TREE_SCALE_MIN = 0.1
const TREE_SCALE_MAX = 0.2
func generate_forest() -> void:
	var tree_count = 0
	
	for x in range(int(MAP_SIZE.x/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
		for y in range(int(MAP_SIZE.y/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
			var _new_position = DIVISION_FACTOR*Vector2(x + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS), y + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS)) - Vector2(MAP_SIZE)/2 - Vector2(TREE_BORDER_LENGTH, TREE_BORDER_LENGTH)
			
			if is_in_base(_new_position) or is_in_path(_new_position) or is_in_decoration(_new_position) or is_in_arena(_new_position):
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

const CHANCE_TO_SPAWN_THING := 0.1
const DISPLACEMENT_TO_CENTER := 3.0
func generate_interests_camps() -> void:
	for i in interest_points_list:
		var _new_plant = pre_plant.instantiate()
		_new_plant.position = Vector3(i.x, -0.2, i.y)
		_new_plant.rotate(Vector3.UP, randf_range(-PI, PI))
		_new_plant.plant = plants[randi_range(0, plants.size()-1)]
		add_child(_new_plant)

const DECORATION_DISTANCE := 0.75
var decorations_points = PackedVector2Array()
func generate_decoration() -> void:
	for i in range(50):
		var _decoration = randi_range(0, decorations.size()-1)
		var _new_position = Vector2(randf_range(-MAP_SIZE.x/2.0, MAP_SIZE.x/2.0), randf_range(-MAP_SIZE.y/2.0, MAP_SIZE.y/2.0))
		if is_in_base(_new_position) or is_in_path(_new_position) or is_in_arena(_new_position):
			continue
		decorations_points.append(_new_position)
		var _new_decoration = decorations[_decoration].instantiate()
		_new_decoration.position = Vector3(_new_position.x, 0.0, _new_position.y)
		add_child(_new_decoration)

#var _displace_vec = path[p].direction_to(path[p+1]).rotated(PI/2.0) * DISPLACEMENT_TO_CENTER if p+1 < path.size() else path[p-1].direction_to(path[p]) * DISPLACEMENT_TO_CENTER
#_new_decoration.position = Vector3(path[p].x, -0.3, path[p].y) + Vector3(_displace_vec.x, 0.0, _displace_vec.y)
#_new_tribal_torch.look_at(Vector3(_displace_vec.x, 0.0, _displace_vec.y).rotated(Vector3.UP, PI))

func is_in_decoration(pos : Vector2) -> bool:
	for i in decorations_points:
		if i.distance_to(pos) < DECORATION_DISTANCE:
			return true
	return false

func is_in_base(pos : Vector2) -> bool:
	if pos.distance_to(bases_position[0]) < NO_TREE_CAMP_DISTANCE or pos.distance_to(bases_position[1]) < NO_TREE_CAMP_DISTANCE:
		return true
	return false

func is_in_path(pos : Vector2) -> bool:
	for paths in paths_points_list:
		for points in paths:
			if pos.distance_to(points) < NO_TREE_PATH_DISTANCE:
				return true
	return false

func is_in_arena(pos : Vector2) -> bool:
	if pos.distance_to(Vector2(0.0, 0.0)) < ARENA_SIZE:
		return true
	return false

func spawn_player(pos : Vector3, center_spawn : Vector3) -> void:
	var _new_player = pre_player.instantiate()
	_new_player.position = pos
	_new_player.target_direction = pos.direction_to(center_spawn)
	add_child(_new_player)
	players.append(_new_player)
