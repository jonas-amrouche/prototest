extends Node

const CAMP_DISTANCE_TO_CENTER = 100.0
var bases : Array[Object]

var interest_points_list = PackedVector2Array()
var paths_points_list : Array[PackedVector2Array]
var new_interest_points_list : Dictionary
const LANE_POINTS = 8
const LANE_RESOLUTION = 1.0

const POINT_CELL_DIVISION = 8 # 28
const PATH_RANDOM_CELLS = 4.0 #0.4
const NO_PATH_BORDER_LENGTH = 20.0

const MIN_INTEREST_POINTS = 32#32
const MAX_INTEREST_POINTS = 64#64
const MIN_INTEREST_SIZE = 2.0
const MAX_INTEREST_SIZE = 6.0
const INTEREST_BORDER = 7.0

const PATH_RESOLUTION = 1.0
const SIN_DIVISION = 3.0
const SIN_FORCE = 2.0
const ARENA_PATH_MULTIPLIER = 0.2
const MIN_PATH = 1
const MAX_PATH = 3

const ARENA_SIZE = 10.0

const COLLISION_GRID_DIVISION := 1.0

const DISPLACEMENT_TO_CENTER := 3.0
var camp_points_list : PackedVector2Array

const DECORATION_DISTANCE := 1.5
var decorations_points = PackedVector2Array()

var generated_data : Dictionary
var collision_spawn_thread : Thread

@onready var world = get_parent()
@onready var resources = world.get_node("GameResources")
@onready var multi_tree = world.get_node("MultiTrees")
@onready var ground_mesh = world.get_node("Ground")
@onready var rivers = world.get_node("Rivers")
@onready var trees_body = world.get_node("NavMesh/TreesBody")
@onready var ground_body = world.get_node("NavMesh/GroundBody")
@onready var navmesh = world.get_node("NavMesh")
@onready var camps = world.get_node("Camps")
@onready var monsters = world.get_node("Monsters")
@onready var items = world.get_node("Items")

func generate_map() -> void:
	generated_data["bases"] = PackedVector3Array()
	generated_data["paths_points"] = Array()
	generated_data["interest_points"] = Dictionary()
	generated_data["arena"] = Vector3()
	generated_data["trees"] = Array()
	generated_data["camps"] = Dictionary()
	generated_data["camps"]["position"] = Array()
	generated_data["camps"]["type"] = Array()
	generated_data["map_size"] = Basics.MAP_SIZE
	
	randomize()
	generate_bases()
	spawn_bases()
	generate_lanes()
	generate_points_and_paths()
	generate_mid_arena()
	#mirror_points()
	generated_data["interest_points"] = new_interest_points_list
	generated_data["paths_points"] = paths_points_list
	#generate_decoration()
	generate_forest()
	generate_camps()
	#generate_structures()
	
	#var _bases_positions = [Vector2(bases[0].position.x, bases[0].position.z), Vector2(bases[1].position.x, bases[1].position.z)]
	world.rpc("send_map_data_to_player", generated_data)
	world.send_map_data_to_player(generated_data)

func spawn_map(data : Dictionary) -> void:
	generated_data = data
	
	spawn_bases()
	spawn_arena()
	#spawn_collisions_new()
	collision_spawn_thread = Thread.new()
	collision_spawn_thread.start(spawn_collisions.bind(generated_data))
	#spawn_collisions_old()
	spawn_trees()
	spawn_camps()

func spawn_bases() -> void:
	for base_pos in generated_data["bases"]:
		var _new_base = resources.base_structure.instantiate()
		_new_base.position = Vector3(base_pos.x, 0.0, base_pos.y)
		navmesh.add_child(_new_base)
		_new_base.scale *= Vector3(sign(base_pos.x), 1.0, -sign(base_pos.x))
		bases.append(_new_base)

func spawn_arena() -> void:
	var _new_arena = resources.arena_structure.instantiate()
	_new_arena.position = generated_data["arena"]
	add_child(_new_arena)

func spawn_trees() -> void:
	for i in range(generated_data["trees"].size()):
		var _transform = generated_data["trees"][i]
		multi_tree.multimesh.set_instance_transform(i, _transform)
		#add_collision_cube(Vector2(_transform.origin.x, _transform.origin.z))
	multi_tree.multimesh.visible_instance_count = generated_data["trees"].size()
	

func spawn_camps() -> void:
	for i in range(generated_data["camps"]["position"].size()):
		var _new_camp = resources.camp_structure.instantiate()
		_new_camp.position = generated_data["camps"]["position"][i]
		_new_camp.camp = resources.camps_list[generated_data["camps"]["type"][i]]
		camps.add_child(_new_camp)

func generate_bases() -> void:
	var _random_vector = Vector2(0, CAMP_DISTANCE_TO_CENTER).rotated(PI/4.0)
	generated_data["bases"] = [_random_vector, _random_vector.rotated(PI)]

func generate_lanes() -> void:
	for l in range(0, 3):
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

func generate_points_and_paths() -> void:
	
	# Generate arena points for path (Deleted at the end)
	interest_points_list.append(Vector2(0.0, 0.0))
	#interest_points_list.append(Vector2(-55.0, 0.0))
	#interest_points_list.append(Vector2(55.0, 0.0))
	#for base in bases:
		#for i in range(3):
			#var _pos = base.get_node("PathStarts").get_node(str(i+1)).global_position
			#interest_points_list.append(Vector2(_pos.x, _pos.z))
	
	# Generate grid
	var _grid_point_list : PackedVector2Array
	for x in range(Basics.MAP_SIZE.x/POINT_CELL_DIVISION):
		for y in range(Basics.MAP_SIZE.y/POINT_CELL_DIVISION):
			var _new_point = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*float(POINT_CELL_DIVISION) - Vector2(Basics.MAP_SIZE)/2
			#var _new_point = Vector2(x+1, y+1)*float(POINT_CELL_DIVISION) - Vector2(Basics.MAP_SIZE)/2
			if is_close_to_square_border(Basics.MAP_SIZE, _new_point + Basics.MAP_SIZE/2.0, NO_PATH_BORDER_LENGTH) or is_in_base(_new_point):
				continue
			_grid_point_list.append(_new_point)
	
	var _interest_point_num = randi_range(MIN_INTEREST_POINTS, MAX_INTEREST_POINTS)
	print(_interest_point_num)
	
	var _break_count : int = 0
	#var grid_points_removed = 0
	
	# Select random point, assign a size, then select the next one not in the range
	while new_interest_points_list.size() < _interest_point_num and _grid_point_list.size() > 0:
		var _rand_idx = randi_range(0, _grid_point_list.size()-1)
		var _is_valid = true
		for i in range(new_interest_points_list.size()):
			# ERROR au lancement (index trop grand (new_interest_points_list.keys()[i]))
			if _grid_point_list[_rand_idx].distance_to(new_interest_points_list.keys()[i]) < new_interest_points_list.values()[i] + INTEREST_BORDER:
				_grid_point_list.remove_at(_rand_idx)
				#grid_points_removed += 1
				_is_valid = false
				break
		if _is_valid:
			#DebugFeatures.debug_box(Vector3(_grid_point_list[_rand_idx].x, 0.0, _grid_point_list[_rand_idx].y))
			new_interest_points_list[_grid_point_list[_rand_idx]] = randf_range(MIN_INTEREST_SIZE, MAX_INTEREST_SIZE)
			
			#TEMP
			interest_points_list.append(_grid_point_list[_rand_idx])
			
		_break_count += 1
		
		#if there is already to many large areas we don't want to be blocked
		if _break_count > 400:
			print("SAFETY BREAK POINT CALCULATION")
			break
	print("while loops : ", _break_count)
	# Generate interest points
	#for x in range(Basics.MAP_SIZE.x/POINT_CELL_DIVISION):
		#for y in range(Basics.MAP_SIZE.y/POINT_CELL_DIVISION):
			#var _new_point = Vector2(x+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS), y+1 + randf_range(-PATH_RANDOM_CELLS, PATH_RANDOM_CELLS))*float(POINT_CELL_DIVISION) - Vector2(Basics.MAP_SIZE)/2
			#if is_close_to_square_border(Basics.MAP_SIZE, _new_point + Basics.MAP_SIZE/2.0, NO_PATH_BORDER_LENGTH):
				#continue
			#interest_points_list.append(_new_point)
	
	# Generate path between interest points
	for p in interest_points_list:
		var _point_linked = PackedVector2Array()
		var _path_number = 4 if p == Vector2() else randi_range(MIN_PATH, MAX_PATH)
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
				#DebugFeatures.debug_box(self, Vector3(p.x + _point_pos.x, 0.0, p.y + _point_pos.y))
			paths_points_list.append(_temp_point_list)
			
	
	interest_points_list = interest_points_list.slice(LANE_POINTS*1, interest_points_list.size())
	
	# Clear interest points in bases and arena
	var _removed_value = 0
	for p in range(interest_points_list.size()):
		if is_in_base(interest_points_list[p - _removed_value]) or is_in_arena(interest_points_list[p - _removed_value]):
			interest_points_list.remove_at(p - _removed_value)
			_removed_value += 1

func generate_mid_arena() -> void:
	generated_data["arena"] = Vector3(0.0, 0.0, 0.0)

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
	
	var _removed_new_interest_count := 0
	for i in range(new_interest_points_list.size()):
		if is_on_right_side(new_interest_points_list.keys()[i - _removed_new_interest_count]):
			new_interest_points_list.erase(new_interest_points_list.keys()[i - _removed_new_interest_count])
			_removed_new_interest_count += 1
	
	var _new_miror_paths = paths_points_list.duplicate(true)
	for pa in range(_new_miror_paths.size()):
		for po in range(_new_miror_paths[pa].size()):
			_new_miror_paths[pa].set(po, _new_miror_paths[pa][po] * -1.0)
	paths_points_list.append_array(_new_miror_paths)
	
	for i in range(interest_points_list.size()):
		interest_points_list.append(interest_points_list[i] * -1.0)
		
	for i in range(new_interest_points_list.size()):
		new_interest_points_list[new_interest_points_list.keys()[i] * -1.0] = new_interest_points_list.values()[i]

func is_on_right_side(point : Vector2) -> bool:
	if (bases[1].position.x - bases[0].position.x)*(point.y - bases[0].position.y)-(point.x - bases[0].position.x)*(bases[1].position.y - bases[0].position.y) > 0:
		return true
	return false

#func spawn_collisions_new() -> void:
	#pass

func spawn_collisions_old() -> void:
	print("col started")
	var _walls_points : PackedVector2Array
	var _walls_id : PackedInt64Array
	for x in range(int(Basics.MAP_SIZE.x/COLLISION_GRID_DIVISION)):
		for y in range(int(Basics.MAP_SIZE.y/COLLISION_GRID_DIVISION)):
			var _position = Vector2(x, y) * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
			if !(is_in_base(_position) or is_in_path(_position) or is_in_arena(_position)):
				_walls_points.append(Vector2(x, y))
				_walls_id.append(-1)
				#for vec in [Vector2(x-1, y-1), Vector2(x, y-1), Vector2(x+1, y-1), Vector2(x-1, y), Vector2(x+1, y), Vector2(x-1, y+1), Vector2(x, y+1), Vector2(x+1, y+1)]:
					#if _walls_points.find(vec) != -1:
						#_walls_points.append(Vector2(x, y))
						#_walls_id.append(_walls_id[_walls_points.find(vec)])
						#break
				#if _walls_points.find(Vector2(x, y)) == -1:
					#_walls_points.append(Vector2(x, y))
					#_walls_id.append(rand_from_seed(int(str(x) + str(y)))[1])
	
	for i in range(_walls_points.size()):
		var x = _walls_points[i].x
		var y = _walls_points[i].y
		for vec in [Vector2(x-1, y+1), Vector2(x, y+1), Vector2(x+1, y+1), Vector2(x-1, y), Vector2(x+1, y), Vector2(x-1, y-1), Vector2(x, y-1), Vector2(x+1, y-1)]:
			if _walls_points.has(vec) and _walls_id[_walls_points.find(vec)] != -1:
				_walls_id[i] = _walls_id[_walls_points.find(vec)]
				break
		if _walls_id[i] == -1:
			_walls_id[i] = rand_from_seed(int(str(x) + str(y)))[1]
	
	print(_walls_points.size())
	#var _unsorted_collision_chunks : Dictionary[Vector2, int]
	var _final_wall_points : PackedVector2Array = _walls_points
	var _final_wall_id : PackedInt64Array = _walls_id
	#for w in range(_walls_points.size()):
		#var _wall_neighbor = 0
		#if _walls_points.has(_walls_points[w] - Vector2(1, 0)): _wall_neighbor += 1
		#if _walls_points.has(_walls_points[w] + Vector2(1, 0)): _wall_neighbor += 1
		#if _walls_points.has(_walls_points[w] - Vector2(0, 1)): _wall_neighbor += 1
		#if _walls_points.has(_walls_points[w] + Vector2(0, 1)): _wall_neighbor += 1
		#if _wall_neighbor != 4:
			#_final_wall_points.append(_walls_points[w])
			#_final_wall_id.append(_walls_id[w])
			##add_collision_cube(wall * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2)
	
	#print(_unsorted_collision_chunks)
	var _reverse_dictionnary : Dictionary[int, PackedVector2Array]
	for i in range(_final_wall_id.size()):
		var _arr = PackedVector2Array()
		if _reverse_dictionnary.has(_final_wall_id[i]):
			_arr = _reverse_dictionnary[_final_wall_id[i]]
		_arr.append(_final_wall_points[i])
		_reverse_dictionnary[_final_wall_id[i]] = _arr
	
	print(_reverse_dictionnary)
	for g in range(_reverse_dictionnary.keys().size()):
		#if _sorted_collision_points[g].size() > 8:
			#var _pos_array = PackedVector2Array()
			#for point in _sorted_collision_points[g]:
				#_pos_array.append(point * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2)
			#add_collision_polygon(_pos_array)
		#else:
		for point in _reverse_dictionnary.values()[g]:
			var _pos = point * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
			#add_collision_cube(_pos)
			DebugFeatures.debug_box(world, Vector3(_pos.x+randf_range(-0.05, 0.05), 1.0, _pos.y+randf_range(-0.05, 0.05)), 1.0, Color(float("0." + str(rand_from_seed(g)[0])), float("0." + str(rand_from_seed(g+1)[0])), float("0." + str(rand_from_seed(g+2)[0]))))

func spawn_collisions(_datas : Dictionary) -> void:
	var _walls : Array[Vector2]
	for x in range(int(Basics.MAP_SIZE.x/COLLISION_GRID_DIVISION)):
		for y in range(int(Basics.MAP_SIZE.y/COLLISION_GRID_DIVISION)):
			var _position = Vector2(x, y) * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
			if !(is_in_base(_position) or is_in_path(_position) or is_in_arena(_position)):
				_walls.append(Vector2(x, y))
	
	var _unsorted_collision_points : PackedVector2Array
	for wall in _walls:
		var _wall_neighbor = 0
		if _walls.has(wall - Vector2(1, 0)): _wall_neighbor += 1
		if _walls.has(wall + Vector2(1, 0)): _wall_neighbor += 1
		if _walls.has(wall - Vector2(0, 1)): _wall_neighbor += 1
		if _walls.has(wall + Vector2(0, 1)): _wall_neighbor += 1
		if _wall_neighbor != 4:
			_unsorted_collision_points.append(wall)
			add_collision_cube(wall * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2)
	print("collision loaded")
	navmesh.call_deferred("bake_navigation_mesh")
	#var _sorted_collision_points : Array[PackedVector2Array]
	#var _lost_neighbors : PackedVector2Array
	#while _unsorted_collision_points.size() > 0:
		#var _current_point = _unsorted_collision_points[0]
		#_unsorted_collision_points.remove_at(0)
		#var _has_neighbor = true
		#var _group_array = PackedVector2Array()
		#_group_array.append(_current_point)
		#while _has_neighbor:
			#_has_neighbor = false
			#var _vec_won : Vector2
			#for nx in range(-1, 2):
				#for ny in range(-1, 2):
					#if nx == 0 and ny == 0: continue
					#if _unsorted_collision_points.has(_current_point + Vector2(nx, ny)):
						#if _has_neighbor:
							#_lost_neighbors.append(_current_point + Vector2(nx, ny))
							#continue
						#
						#_unsorted_collision_points.remove_at(_unsorted_collision_points.find(_current_point + Vector2(nx, ny)))
						#
						#_group_array.append(_current_point + Vector2(nx, ny))
						#
						#_vec_won = Vector2(nx, ny)
						#_has_neighbor = true
			#_current_point += _vec_won
			#if !_has_neighbor and _lost_neighbors.size() > 0:
				#_current_point = _lost_neighbors[0]
				#_lost_neighbors.remove_at(0)
				#if _unsorted_collision_points.has(_current_point):
					#_unsorted_collision_points.remove_at(_unsorted_collision_points.find(_current_point))
				#_has_neighbor = true
				#_group_array.append(_current_point)
		#_sorted_collision_points.append(_group_array)
	
	#for g in range(_sorted_collision_points.size()):
		#if _sorted_collision_points[g].size() > 2:
			#var _pos_array = PackedVector2Array()
			#for point in _sorted_collision_points[g]:
				#_pos_array.append(point * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2)
			#add_collision_polygon(_pos_array)
		#else:
			#for point in _sorted_collision_points[g]:
				#var _pos = point * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
				#add_collision_cube(_pos)
				
		#for point in _sorted_collision_points[g]:
			#var _pos = point * COLLISION_GRID_DIVISION - Vector2(Basics.MAP_SIZE)/2
			#DebugFeatures.debug_box(world, Vector3(_pos.x+randf_range(-0.05, 0.05), 1.0, _pos.y+randf_range(-0.05, 0.05)), 1.0, Color(float("0." + str(rand_from_seed(g)[0])), float("0." + str(rand_from_seed(g+1)[0])), float("0." + str(rand_from_seed(g+2)[0]))))

func is_close_to_square_border(square_size : Vector2, detection_point : Vector2, detection_length : float) -> bool:
	if detection_point.x > square_size.x - detection_length or detection_point.x < detection_length or detection_point.y > square_size.y - detection_length or detection_point.y < detection_length:
		return true
	return false

const DIVISION_FACTOR := 2.0
const TREE_RANDOM_CELLS = 0.4
const TREE_BORDER_LENGTH := 2.0
const NO_TREE_BASE_DISTANCE := 27.0
const NO_TREE_PATH_DISTANCE := 2.5
const TREE_ROTATION_MAX = PI/8.0
const TREE_SCALE_MIN = 0.1#0.08
const TREE_SCALE_MAX = 0.18#0.12
func generate_forest() -> void:
	
	for x in range(int(Basics.MAP_SIZE.x/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
		for y in range(int(Basics.MAP_SIZE.y/DIVISION_FACTOR + TREE_BORDER_LENGTH)):
			var _new_position = DIVISION_FACTOR*Vector2(x + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS), y + randf_range(-TREE_RANDOM_CELLS, TREE_RANDOM_CELLS)) - Vector2(Basics.MAP_SIZE)/2 - Vector2(TREE_BORDER_LENGTH, TREE_BORDER_LENGTH)/2
			
			if is_in_base(_new_position) or is_in_path(_new_position) or is_in_decoration(_new_position) or is_in_arena(_new_position) or is_in_interest(_new_position) or (is_in_river(_new_position) and !is_beyond_map_limit(_new_position)):
				continue
			
			var _basis_vec = Vector3(randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0, randf()*PI*4.0-PI*2.0).normalized()
			var _basis = Basis(_basis_vec, randf_range(-TREE_ROTATION_MAX, TREE_ROTATION_MAX)).rotated(Vector3.UP, randf_range(-PI, PI))
			var _transform = Transform3D(_basis * randf_range(TREE_SCALE_MIN, TREE_SCALE_MAX), Vector3(_new_position.x, ground_mesh.position.y, _new_position.y))
			generated_data["trees"].append(_transform)

func add_collision_cube(pos : Vector2) -> void:
	var _new_collision_cube = CollisionShape3D.new()
	_new_collision_cube.shape = BoxShape3D.new()
	_new_collision_cube.shape.size = Vector3(1.0, 4.0, 1.0)
	_new_collision_cube.position = Vector3(pos.x, 1.5, pos.y)
	#_new_collision_cube.rotation = Vector3(0, PI/4.0, 0)
	trees_body.call_deferred("add_child", _new_collision_cube)

func add_collision_polygon(polygon_shape : PackedVector2Array) -> void:
	var _new_collision_cube = CollisionPolygon3D.new()
	_new_collision_cube.rotation.x = PI/2.0
	_new_collision_cube.polygon = polygon_shape
	_new_collision_cube.depth = 4.0
	#_new_collision_cube.shape.size = Vector3(1.0, 4.0, 1.0)
	_new_collision_cube.position = Vector3(0, 2, 0)
	trees_body.add_child(_new_collision_cube)

func generate_camps() -> void:
	for i in range(generated_data["interest_points"].size()):
		generated_data["camps"]["position"].append(Vector3(new_interest_points_list.keys()[i].x, -0.22, new_interest_points_list.keys()[i].y))
		generated_data["camps"]["type"].append(randi_range(0, resources.camps_list.size()-1))

const CHANCE_TO_SPAWN_TOWER := 0.05
func generate_structures() -> void:
	for i in interest_points_list:
		if randf() < CHANCE_TO_SPAWN_TOWER:
			var _new_tower = resources.tower_structure.instantiate()
			_new_tower.position = Vector3(i.x, -0.2, i.y)
			add_child(_new_tower)

func generate_decoration() -> void:
	for i in range(150):
		var _decoration = randi_range(0, resources.decorations_models.size()-1)
		var _new_position = Vector2(randf_range(-Basics.MAP_SIZE.x/2.0, Basics.MAP_SIZE.x/2.0), randf_range(-Basics.MAP_SIZE.y/2.0, Basics.MAP_SIZE.y/2.0))
		if is_in_base(_new_position) or is_in_path(_new_position) or is_in_arena(_new_position):
			continue
		decorations_points.append(_new_position)
		var _new_decoration = resources.decorations_models[_decoration].instantiate()
		_new_decoration.position = Vector3(_new_position.x, ground_mesh.position.y, _new_position.y)
		_new_decoration.rotation = Vector3(0.0, randf_range(-PI, PI), 0.0)
		add_child(_new_decoration)

func is_in_decoration(pos : Vector2) -> bool:
	for i in decorations_points:
		if i.distance_to(pos) < DECORATION_DISTANCE:
			return true
	return false

func is_in_base(pos : Vector2) -> bool:
	for base in generated_data["bases"]:
		#var _base_pos = Vector2(base.position.x+(NO_TREE_BASE_DISTANCE*sign(base.position.x)), base.position.z+(NO_TREE_BASE_DISTANCE*-sign(base.position.x)))
		var _base_pos = Vector2(base.x, base.y)
		if pos.distance_to(_base_pos) < NO_TREE_BASE_DISTANCE:
			return true
	return false

#func is_in_base(pos : Vector2) -> bool:
	#for base in bases:
		#var _base_pos = Vector2(base.position.x+(NO_TREE_BASE_DISTANCE*sign(base.position.x)), base.position.z+(NO_TREE_BASE_DISTANCE*-sign(base.position.x)))
		#if pos.x > _base_pos.x - NO_TREE_BASE_DISTANCE and pos.x < _base_pos.x + NO_TREE_BASE_DISTANCE and pos.y > _base_pos.y - NO_TREE_BASE_DISTANCE and pos.y < _base_pos.y + NO_TREE_BASE_DISTANCE:
			#return true
	#return false

func is_in_path(pos : Vector2) -> bool:
	for paths in generated_data["paths_points"]:
		for points in paths:
			#for base in bases:
			if pos.distance_to(points) < NO_TREE_PATH_DISTANCE: # * (min(50.0, points.distance_to(Vector2(base.position.x, base.position.z)))/50.0)
				return true
	return false

func is_in_interest(pos : Vector2) -> bool:
	for i in range(new_interest_points_list.size()):
		if pos.distance_to(new_interest_points_list.keys()[i]) < new_interest_points_list.values()[i]:
			return true
	return false

func is_in_river(pos : Vector2) -> bool:
	var _noise = rivers.mesh.get("material").get("shader_parameter/noise").noise
	var _new_pos = (pos+Vector2(250.0, 250.0)/2.0)/Vector2(250.0, 250.0)*2048.0
	var _val = (_noise.get_noise_2d(int(_new_pos.x), int(_new_pos.y))+1.0)/2.0
	#return _val > 0.5 and _val < 0.7
	return false

const PATH_LIMIT = 15.0
func is_beyond_map_limit(pos : Vector2) -> bool:
	return !(pos.x > -Basics.MAP_SIZE.x/2.0+PATH_LIMIT and pos.x < Basics.MAP_SIZE.x/2.0-PATH_LIMIT  and pos.y > -Basics.MAP_SIZE.x/2.0+PATH_LIMIT and pos.y < Basics.MAP_SIZE.x/2.0-PATH_LIMIT)

func is_in_arena(pos : Vector2) -> bool:
	if pos.distance_to(Vector2(0.0, 0.0)) < ARENA_SIZE:
		return true
	return false

func _exit_tree():
	if collision_spawn_thread.is_alive():
		collision_spawn_thread.wait_to_finish()
