extends Node3D

var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")

@onready var player := get_parent()
@onready var update_fog_timer := $UpdateFog

var generated_data : Dictionary

var current_fog_map : Image
var fading_fog_map : Image
const FOG_RESOLUTION = 1
const FOG_TEXTURE_SIZE = Vector2i(int(Basics.MAP_SIZE.x), int(Basics.MAP_SIZE.y)) * FOG_RESOLUTION
const FOG_PLAYER_SIZE = 20 * FOG_RESOLUTION
const FOG_BEACON_SIZE = 10 * FOG_RESOLUTION
const FOG_BASE_SIZE = 48 * FOG_RESOLUTION
func initialize_fog(data : Dictionary) -> void:
	generated_data = data
	current_fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	current_fog_map.fill(Color(1.0, 1.0, 1.0))
	fading_fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	fading_fog_map.fill(Color(1.0, 1.0, 1.0))
	player.hud.mini_map.initialize_fog_display(generated_data["bases"], FOG_BASE_SIZE, FOG_PLAYER_SIZE, FOG_TEXTURE_SIZE)
	update_fog()
	update_fog_timer.start()

func update_fog() -> void:
	current_fog_map.fill(Color(1.0, 1.0, 1.0))
	#fog_map.fill(Color(0.0, 0.0, 0.0))
	#var _player_position = world_to_fog_position(Vector2(player.global_position.x, player.global_position.z))
	#var _player_circle = get_circle(FOG_PLAYER_SIZE)
	#fog_map.blend_rect(_player_circle, _player_circle.get_used_rect(), _player_position - _player_circle.get_size()/2)
	for base_pos in generated_data["bases"]:
		var _base_pos = world_to_fog_position(base_pos)
		var _base_circle = get_circle(FOG_BASE_SIZE)
		current_fog_map.blend_rect(_base_circle, _base_circle.get_used_rect(), _base_pos - _base_circle.get_size()/2)
	for beacon in player.world.beacons.get_children():
		var _beacon_position = world_to_fog_position(Vector2(beacon.global_position.x, beacon.global_position.z))
		var _beacon_circle = get_circle(FOG_BEACON_SIZE)
		current_fog_map.blend_rect(_beacon_circle, _beacon_circle.get_used_rect(), _beacon_position - _beacon_circle.get_size()/2)
	for temp_v in player.world.temp_vision.get_children():
		var _temp_vision_position = world_to_fog_position(Vector2(temp_v.global_position.x, temp_v.global_position.z))
		var _temp_vision_circle = get_circle(temp_v.radius)
		current_fog_map.blend_rect(_temp_vision_circle, _temp_vision_circle.get_used_rect(), _temp_vision_position - _temp_vision_circle.get_size()/2)
	
	# Send vision map to minimap
	player.hud.mini_map.update_fog_display(current_fog_map, player.global_position)
	
	# Send vision map to map script to manage entities visibility
	player.world.vision_update(self, current_fog_map)

func _process(delta: float) -> void:
	interpolate_fog_image(delta)

var temporal_fade_speed = 1.0
func interpolate_fog_image(delta : float) -> void:
	temporal_fade_speed = 0.75
	for x in range(fading_fog_map.get_width()):
		for y in range(fading_fog_map.get_height()):
			fading_fog_map.set_pixel(x, y, lerp(fading_fog_map.get_pixel(x, y), current_fog_map.get_pixel(x, y), temporal_fade_speed * delta))
	
	send_temporal_fog_result(fading_fog_map)

func send_temporal_fog_result(fog_map : Image) -> void:
	# Send vision map to fog plane
	player.world.fog_plane.mesh.material.set("shader_parameter/fog_texture", ImageTexture.create_from_image(fog_map))

func get_circle(size : float, resize_filter : Image.Interpolation = Image.INTERPOLATE_NEAREST) -> Image:
	var _ring_img = pre_circle_image.duplicate()
	_ring_img.resize(size, size, resize_filter)
	return _ring_img

func has_vision(pos : Vector2i) -> bool:
	
	# TODO bug quand une entité va trop loin (il depasse de la map de vision) pour l'instant je clamp
	var _fog_position = world_to_fog_position(pos).clamp(Vector2i(0, 0), FOG_TEXTURE_SIZE-Vector2i(1, 1))
	return current_fog_map.get_pixel(_fog_position.x, _fog_position.y).r < 0.5

const RAY_NUM = 26
func update_player_vision() -> void:
	clear_temp_vision()
	
	for i in range(RAY_NUM):
		var _vector = Vector3.FORWARD.rotated(Vector3.UP, PI*2.0*(float(i)/float(RAY_NUM)))
		var _length = vision_raycast(_vector)
		for v in range(int(round(_length / RAY_LENGTH * V_PER_RAY))):
			spawn_temp_vision(global_position + _vector * (RAY_LENGTH/float(V_PER_RAY)) * v, 7.0)

const V_PER_RAY := 10
const RAY_LENGTH := 12.0
func vision_raycast(direction : Vector3) -> float:
	var _ray_query = PhysicsRayQueryParameters3D.new()
	_ray_query.from = player.global_position
	_ray_query.to = player.global_position + direction * RAY_LENGTH
	_ray_query.collision_mask = pow(2, 1-1) + pow(2, 4-1)
	var _result = get_world_3d().direct_space_state.intersect_ray(_ray_query)
	if !_result.is_empty():
		return player.position.distance_to(_result.get("position"))
	return RAY_LENGTH

var pre_temp_vision = preload("res://Scenes/Systems/temp_vision.tscn")
func spawn_temp_vision(vision_pos : Vector3, radius : float) -> void:
	var _new_temp_vision = pre_temp_vision.instantiate()
	_new_temp_vision.position = vision_pos
	_new_temp_vision.radius = radius
	player.world.temp_vision.add_child(_new_temp_vision)

func clear_temp_vision() -> void:
	for temp_v in player.world.temp_vision.get_children():
		temp_v.queue_free()

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + Basics.MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_update_fog_timeout():
	update_player_vision()
	update_fog()
