extends Node3D

var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")

@onready var player := get_node("..")

var fog_map : Image
const FOG_RESOLUTION = 2
const FOG_TEXTURE_SIZE = Vector2i(int(Basics.MAP_SIZE.x), int(Basics.MAP_SIZE.y)) * FOG_RESOLUTION
const FOG_PLAYER_SIZE = Vector2i(15, 15) * FOG_RESOLUTION
const FOG_BEACON_SIZE = Vector2i(10, 10) * FOG_RESOLUTION
const FOG_BASE_SIZE = Vector2i(24, 24) * FOG_RESOLUTION
func initialize_fog_map(bases_data : PackedVector2Array) -> void:
	fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	fog_map.fill(Color(1.0, 1.0, 1.0))
	player.hud.mini_map.initialize_fog_display(bases_data, FOG_BASE_SIZE, FOG_PLAYER_SIZE, FOG_TEXTURE_SIZE)
	update_map_fog()

func update_map_fog() -> void:
	fog_map.fill(Color(1.0, 1.0, 1.0))
	var _player_position = world_to_fog_position(Vector2(player.global_position.x, player.global_position.z))
	var _ring_img = pre_circle_image.duplicate()
	_ring_img.resize(FOG_PLAYER_SIZE.x, FOG_PLAYER_SIZE.y, Image.INTERPOLATE_NEAREST)
	fog_map.blend_rect(_ring_img, _ring_img.get_used_rect(), _player_position - _ring_img.get_size()/2)
	#var _beacon_img = pre_circle_image.duplicate()
	for i in player.world.beacons.get_children():
		var _beacon_position = world_to_fog_position(Vector2(i.global_position.x, i.global_position.z))
		_ring_img.resize(FOG_BEACON_SIZE.x, FOG_BEACON_SIZE.y, Image.INTERPOLATE_NEAREST)
		fog_map.blend_rect(_ring_img, _ring_img.get_used_rect(), _beacon_position - _ring_img.get_size()/2)
	
	for i in player.world.temp_vision.get_children():
		var _temp_vision_position = world_to_fog_position(Vector2(i.global_position.x, i.global_position.z))
		_ring_img.resize(i.radius, i.radius, Image.INTERPOLATE_NEAREST)
		fog_map.blend_rect(_ring_img, _ring_img.get_used_rect(), _temp_vision_position - _ring_img.get_size()/2)
		
	player.hud.mini_map.update_fog_display(fog_map, player.global_position)
	
	# Send vision map to ground mesh affacting all landscape because it's the same material instance
	player.world.ground_mesh.mesh.material.next_pass.set("shader_parameter/fog_texture", ImageTexture.create_from_image(fog_map))
	
	# Send vision map to map script to manage entities visibility
	player.world.vision_update(self, fog_map)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + Basics.MAP_SIZE/2.0) * FOG_RESOLUTION)

func _on_update_fog_timeout():
	update_map_fog()
