extends Node3D

const CAMP_DISTANCE_TO_CENTER = 95.0
var bases : Array[Object]
var pre_base = preload("res://Scenes/Props/Base.tscn")
var pre_player = preload("res://Scenes/Player.tscn")
var pre_arena = preload("res://Scenes/Models/MidArenaModel.tscn")
var pre_camp = preload("res://Scenes/Props/Camp.tscn")
var pre_tower = preload("res://Scenes/Props/KnowledgeTower.tscn")
var decorations = [preload("res://Scenes/Models/TribalSanctuaryRoundModel.tscn"), preload("res://Scenes/Models/TribalStoneSquareModel.tscn")]

var camps_list = [preload("res://Ressources/Camps/OmniscientGolem.tres"), \
preload("res://Ressources/Camps/Gobedins.tres"), \
preload("res://Ressources/Camps/DispossessedWillow.tres"), \
preload("res://Ressources/Camps/Grunters.tres"), \
preload("res://Ressources/Camps/LostGhosts.tres")]

var players : Array[Object]
var entities : Array[Object]

@onready var multi_tree = $MultiTrees
#@onready var multi_tree2 = $MultiTrees2
@onready var ground_mesh = $Ground
@onready var ground_body = $NavMesh/GroundBody
@onready var navmesh = $NavMesh
@onready var beacons = $Beacons
@onready var camps = $Camps
@onready var temp_vision = $TempVision
@onready var fog_plane = $FogPlane

func _ready() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
	DisplayServer.window_set_size(Vector2i(1280, 720))
	map_generation()
	spawn_player(get_node("NavMesh/Base/PlayerSpawn/1").global_position, get_node("NavMesh/Base/PlayerSpawn").global_position)
	send_map_data_to_player(paths_points_list, [Vector2(bases[0].position.x, bases[0].position.z), Vector2(bases[1].position.x, bases[1].position.z)], interest_points_list)

func spawn_player(pos : Vector3, center_spawn : Vector3) -> void:
	var _new_player = pre_player.instantiate()
	_new_player.position = pos
	_new_player.target_direction = pos.direction_to(center_spawn)
	add_child(_new_player)
	players.append(_new_player)

func map_generation() -> void:
	randomize()
	generate_bases()
	generate_lanes()
	generate_points_and_paths()
	generate_mid_arena()
	mirror_points()
	#generate_collisions() //
	generate_decoration()
	generate_forest()
	generate_camps()
	generate_structures()

func generate_bases() -> void:
	var _random_vector = Vector2(0, CAMP_DISTANCE_TO_CENTER).rotated(PI/4.0)
	var _bases_pos = [_random_vector, _random_vector.rotated(PI)]
	
	for b in _bases_pos:
		var _new_base = pre_base.instantiate()
		_new_base.position = Vector3(b.x, 0.0, b.y)
		navmesh.add_child(_new_base)
		_new_base.scale *= Vector3(sign(b.x), 1.0, -sign(b.x))
		bases.append(_new_base)

var interest_points_list = PackedVector2Array()
var paths_points_list : Array[PackedVector2Array]
const LANE_POINTS = 8
const LANE_RESOLUTION = 1.0
func generate_lanes() -> void:
	for l in range(3):
		for lp in range(LANE_POINTS):
			var _first_base_pos = bases[0].get_node("PathStarts").get_node(str(l+1)).global_position
			var _second_base_pos = bases[1].get_node("PathStarts").get_node(str(abs(l-3))).global_position
			var _pos = lerp(Vector2(_first_base_pos.x, _first_base_pos.z), Vector2(_second_base_pos.x, _second_base_pos.z), float(lp)/float(LANE_POINTS-1))
			if lp != 0 and lp != LANE_POINTS-1:
				_pos += Vector2(randf_range(-20.0, 20.0), randf_range(-20.0, 20.0))
			interest_points_list.append(_pos)
			if lp == 0:
				continue
			var _last_point = interest_points_list[interest_points_list.size()-2]
			var _temp_point_list = PackedVector2Array()
			for i in range(int(_pos.distance_to(_last_point)/LANE_RESOLUTION)):
				var _point_pos = (_last_point-_pos)/_pos.distance_to(_last_point)/LANE_RESOLUTION * i
				_point_pos += cos(_point_pos.length()/SIN_DIVISION) * _pos.direction_to(_last_point).rotated(PI/2.0) * SIN_FORCE
				_temp_point_list.append(_pos + _point_pos)
			paths_points_list.append(_temp_point_list)

const POINT_CELL_DIVISION = 28
const PATH_RANDOM_CELLS = 0.4
const NO_PATH_BORDER_LENGTH = 20.0
#const CHANCE_TO_REMOVE_POINT = 0.3

const PATH_RESOLUTION = 1.0
const SIN_DIVISION = 3.0
const SIN_FORCE = 2.0
const ARENA_PATH_MULTIPLIER = 0.2
func generate_points_and_paths() -> void:
	
	# Generate arena points for path (Deleted at the end)
	interest_points_list.append(Vector2(0.0, 0.0))
	
	# Generate interest points
	for x in range(Basics.MAP_SIZE.x/POINT_CELL_DIVISION):
		for y in range(Basics.MAP_SIZE.y/POINT_CELL_DIVISION):
			var _new_point = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*float(POINT_CELL_DIVISION) - Vector2(Basics.MAP_SIZE)/2
			if is_close_to_square_border(Basics.MAP_SIZE, _new_point + Basics.MAP_SIZE/2.0, NO_PATH_BORDER_LENGTH):
				continue
			#if randf() < CHANCE_TO_REMOVE_POINT:
				#continue
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
				_temp_point_list.append(p + _point_pos)
			paths_points_list.append(_temp_point_list)
	
	interest_points_list = interest_points_list.slice(LANE_POINTS*3, interest_points_list.size())
	
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
	if (bases[1].position.x - bases[0].position.x)*(point.y - bases[0].position.y)-(point.x - bases[0].position.x)*(bases[1].position.y - bases[0].position.y) > 0:
		return true
	return false

const COLLISION_GRID_DIVISION := 2.0
func generate_collisions() -> void:
	for x in range(int(Basics.MAP_SIZE.x/COLLISION_GRID_DIVISION)):
		for y in range(int(Basics.MAP_SIZE.y/COLLISION_GRID_DIVISION)):
			var _new_position = Vector2(x, y) * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
			if is_in_base(_new_position) or is_in_path(_new_position) or is_in_decoration(_new_position) or is_in_arena(_new_position):
				continue
			add_collision_cube(_new_position)

func send_map_data_to_player(paths_list : Array[PackedVector2Array], bases_list : PackedVector2Array, interests_list : PackedVector2Array):
	for p in players:
		p.vision.initialize_fog_map(bases_list)
		p.hud.init_map_data(paths_list, bases_list, interests_list)

func is_close_to_square_border(square_size : Vector2, detection_point : Vector2, detection_length : float) -> bool:
	if detection_point.x > square_size.x - detection_length or detection_point.x < detection_length or detection_point.y > square_size.y - detection_length or detection_point.y < detection_length:
		return true
	return false

const DIVISION_FACTOR := 2.0
const TREE_RANDOM_CELLS = 0.4
const TREE_BORDER_LENGTH := 2.0
const NO_TREE_BASE_DISTANCE := 8.0
const NO_TREE_PATH_DISTANCE := 2.5
const TREE_ROTATION_MAX = PI/8.0
const TREE_SCALE_MIN = 0.12#0.08
const TREE_SCALE_MAX = 0.2#0.12
func generate_forest() -> void:
	var tree_count = 0
	
	for x in range(int(Basics.MAP_SIZE.x/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
		for y in range(int(Basics.MAP_SIZE.y/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
			var _new_position = DIVISION_FACTOR*Vector2(x + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS), y + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS)) - Vector2(Basics.MAP_SIZE)/2 - Vector2(TREE_BORDER_LENGTH, TREE_BORDER_LENGTH)
			
			if is_in_base(_new_position) or is_in_path(_new_position) or is_in_decoration(_new_position) or is_in_arena(_new_position):
				continue
			
			var _basis_vec = Vector3(randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0).normalized()
			var _basis = Basis(_basis_vec, randf_range(-TREE_ROTATION_MAX, TREE_ROTATION_MAX)).rotated(Vector3.UP, randf_range(-PI, PI))
			var _transform = Transform3D(_basis * randf_range(TREE_SCALE_MIN, TREE_SCALE_MAX), Vector3(_new_position.x, 0, _new_position.y))
			multi_tree.multimesh.set_instance_transform(tree_count, _transform)
			add_collision_cube(_new_position)
			tree_count += 1
	multi_tree.multimesh.visible_instance_count = tree_count
	navmesh.bake_navigation_mesh()

func add_collision_cube(pos : Vector2) -> void:
	var _new_collision_cube = CollisionShape3D.new()
	_new_collision_cube.shape = BoxShape3D.new()
	_new_collision_cube.shape.size = Vector3(2.5, 4.0, 2.5)
	_new_collision_cube.position = Vector3(pos.x, 1.5, pos.y)
	ground_body.add_child(_new_collision_cube)

const DISPLACEMENT_TO_CENTER := 3.0
func generate_camps() -> void:
	for i in interest_points_list:
		var _new_camp = pre_camp.instantiate()
		_new_camp.position = Vector3(i.x, -0.2, i.y)
		_new_camp.camp = camps_list[randi_range(0, camps_list.size()-1)]
		camps.add_child(_new_camp)

const CHANCE_TO_SPAWN_TOWER := 0.05
func generate_structures() -> void:
	for i in interest_points_list:
		if randf() < CHANCE_TO_SPAWN_TOWER:
			var _new_tower = pre_tower.instantiate()
			_new_tower.position = Vector3(i.x, -0.2, i.y)
			add_child(_new_tower)

const DECORATION_DISTANCE := 1.5
var decorations_points = PackedVector2Array()
func generate_decoration() -> void:
	for i in range(150):
		var _decoration = randi_range(0, decorations.size()-1)
		var _new_position = Vector2(randf_range(-Basics.MAP_SIZE.x/2.0, Basics.MAP_SIZE.x/2.0), randf_range(-Basics.MAP_SIZE.y/2.0, Basics.MAP_SIZE.y/2.0))
		if is_in_base(_new_position) or is_in_path(_new_position) or is_in_arena(_new_position):
			continue
		decorations_points.append(_new_position)
		var _new_decoration = decorations[_decoration].instantiate()
		_new_decoration.position = Vector3(_new_position.x, 0.0, _new_position.y)
		add_child(_new_decoration)

func add_entity(entity : Object) -> void:
	entities.append(entity)

func remove_entity(entity : Object) -> void:
	entities.erase(entity)

func vision_update(vision : Object, fog_map : Image) -> void:
	for e in entities:
		if e:
			var _fog_position = vision.world_to_fog_position(Vector2(e.global_position.x, e.global_position.z))
			e.set_visible(fog_map.get_pixel(_fog_position.x, _fog_position.y).r < 0.5)
	
	for c in camps.get_children():
		var _fog_position = vision.world_to_fog_position(Vector2(c.global_position.x, c.global_position.z))
		c.change_camp_visibility(fog_map.get_pixel(_fog_position.x, _fog_position.y).r < 0.5)

func is_in_decoration(pos : Vector2) -> bool:
	for i in decorations_points:
		if i.distance_to(pos) < DECORATION_DISTANCE:
			return true
	return false

func is_in_base(pos : Vector2) -> bool:
	for base in bases:
		var _base_pos = Vector2(base.position.x+(NO_TREE_BASE_DISTANCE*sign(base.position.x)), base.position.z+(NO_TREE_BASE_DISTANCE*-sign(base.position.x)))
		if pos.x > _base_pos.x - NO_TREE_BASE_DISTANCE and pos.x < _base_pos.x + NO_TREE_BASE_DISTANCE and pos.y > _base_pos.y - NO_TREE_BASE_DISTANCE and pos.y < _base_pos.y + NO_TREE_BASE_DISTANCE:
			return true
	return false

func is_in_path(pos : Vector2) -> bool:
	for paths in paths_points_list:
		for points in paths:
			#for base in bases:
			if pos.distance_to(points) < NO_TREE_PATH_DISTANCE: # * (min(50.0, points.distance_to(Vector2(base.position.x, base.position.z)))/50.0)
				return true
	return false

func is_in_arena(pos : Vector2) -> bool:
	if pos.distance_to(Vector2(0.0, 0.0)) < ARENA_SIZE:
		return true
	return false
