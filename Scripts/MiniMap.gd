extends ColorRect

@onready var mini_player := $MiniPlayer
@onready var mini_camera := $MiniCamera
@onready var mini_content := $Content
@onready var mini_movement_lines := $MovementLines
@onready var map_mask := $MapMask

@onready var player = get_node("..").get_node("..").get_node("..")

var map_size : Vector2

var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")
var pre_base_area_texture = preload("res://Assets/2D/Ui/base_area_path.png")
var pre_base_texture = preload("res://Assets/2D/UI/altar_icon.png")
var pre_interest_texture = preload("res://Assets/2D/UI/plant_icon.png")

const MAP_PATH_WIDTH := 9.0
const MAP_MID_WIDTH := 17.0
const MAP_PATH_COLOR := Color(0.275, 0.339, 0.316)
const MAP_BASE_ICON_SIZE := Vector2(30.0, 30.0)
const MAP_BASE_AREA_SIZE := Vector2(50.0, 50.0)
const MAP_ARENA_SIZE := Vector2(50.0, 50.0)
const MAP_INTEREST_ICON_SIZE := Vector2(15.0, 15.0)
func initialize_minimap(m_size : Vector2, paths_data : Array[PackedVector2Array], bases_data : PackedVector2Array, interests_data : PackedVector2Array) -> void:
	# Set map_size
	map_size = m_size
	
	# Format Paths
	var _new_paths_data = Array(PackedVector2Array())
	for path in paths_data:
		var _temp_path = PackedVector2Array()
		for point in path:
			_temp_path.append(world_to_minimap_position(point))
		_new_paths_data.append(_temp_path)
	# Draw Paths
	for path in _new_paths_data:
		draw_custom_line(path, MAP_PATH_WIDTH, MAP_PATH_COLOR)
	
	# Draw Camps Zone Icons
	for base in bases_data:
		draw_icon(base, MAP_BASE_AREA_SIZE, pre_base_area_texture, MAP_PATH_COLOR)
	
	# Draw Arena Zone Icons
	draw_icon(Vector2(0.0, 0.0), MAP_ARENA_SIZE, pre_base_area_texture, MAP_PATH_COLOR)
		
	# Draw Interest Icons
	for interest in interests_data:
		draw_icon(interest, MAP_INTEREST_ICON_SIZE, pre_interest_texture)
	
	# Draw Camps Icons
	for base in bases_data:
		draw_icon(base, MAP_BASE_ICON_SIZE, pre_base_texture)

func draw_custom_line(points : PackedVector2Array, width : float, tint : Color, parent : Object = mini_content) -> void:
	var _new_line = Line2D.new()
	_new_line.points = points
	_new_line.width = width
	_new_line.default_color = tint
	_new_line.joint_mode = Line2D.LINE_JOINT_ROUND
	_new_line.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_new_line.end_cap_mode = Line2D.LINE_CAP_ROUND
	_new_line.antialiased = true
	parent.add_child(_new_line)

func clear_movement_lines() -> void:
	for l in mini_movement_lines.get_children():
		l.queue_free()

const MOVEMENT_LINE_WIDTH := 1.0
func update_movement_line(nav : NavigationAgent3D) -> void:
	clear_movement_lines()
	var _2d_map_navigation_path = PackedVector2Array()
	for p in nav.get_current_navigation_path():
		_2d_map_navigation_path.append(world_to_minimap_position(Vector2(p.x, p.z)))
	draw_custom_line(_2d_map_navigation_path, MOVEMENT_LINE_WIDTH, Color(1.0, 1.0, 1.0, 1.0), mini_movement_lines)

func draw_icon(pos : Vector2, icon_size : Vector2, icon : Texture2D, tint : Color = Color(1.0, 1.0, 1.0, 1.0)) -> void:
	var _new_base_icon = TextureRect.new()
	_new_base_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_new_base_icon.size = icon_size
	_new_base_icon.texture = icon
	_new_base_icon.position = world_to_minimap_position(pos) - _new_base_icon.size/2.0
	_new_base_icon.self_modulate = tint
	mini_content.add_child(_new_base_icon)

func world_to_minimap_position(pos : Vector2) -> Vector2:
	return (pos + map_size/2.0)/map_size*mini_content.size

func initialize_fog(bases_data : PackedVector2Array, fog_base_size : Vector2i, fog_player_size : Vector2i, fog_texture_size : Vector2i) -> void:
	map_mask.material.set_shader_parameter("base_fog_size", float(fog_base_size.x)/2.0/float(fog_texture_size.x))
	map_mask.material.set_shader_parameter("player_fog_size", float(fog_player_size.x)/4.5/float(fog_texture_size.x))
	map_mask.material.set_shader_parameter("base1_pos", (bases_data[0]+map_size/2.0)/map_size)
	map_mask.material.set_shader_parameter("base2_pos", (bases_data[1]+map_size/2.0)/map_size)

func update_fog(fog_map : Image, fog_player_size : Vector2i, player_position : Vector3) -> void:
	var _new_fog_map = fog_map.duplicate()
	var _player_img = pre_circle_image.duplicate()
	_player_img.resize(fog_player_size.x, fog_player_size.y, Image.INTERPOLATE_NEAREST)
	_new_fog_map.blend_rect(_player_img, _player_img.get_used_rect(), player.world_to_fog_position(Vector2(player_position.x, player_position.z)) - _player_img.get_size()/2)
	map_mask.texture = ImageTexture.create_from_image(fog_map)
	map_mask.material.set_shader_parameter("player_pos", (Vector2(player_position.x, player_position.z)+map_size/2.0)/map_size)

func update_player_position(pos : Vector3) -> void:
	mini_player.position = (Vector2(pos.x, pos.z) + map_size/2.0)*(size.x/(map_size.x/2.0))/2.0 - mini_player.size/2.0

func update_camera_position(pos : Vector3, camera_base_position : Vector3) -> void:
	mini_camera.position = (Vector2(pos.x, pos.z - camera_base_position.z) + map_size/2.0)*(size.x/(map_size.x/2.0))/2.0 - mini_camera.size/2.0

var cursor_pos = Vector2()
func _on_gui_input(event):
	if event is InputEventMouseButton:
		if event.button_index == 1:
			if event.pressed:
				player.set_moving_map(true)
			else:
				player.set_moving_map(false)
		#elif event.button_index == 2:
			#if event.pressed:
				#cursor_pos = ((viewport.get_mouse_position() - position) / (size.x/(map_size.x/2.0))*2.0 - map_size/2.0)
				#nav.target_position = Vector3(cursor_pos.x, 0, cursor_pos.y)
	if event is InputEventMouseMotion:
		cursor_pos = ((get_viewport().get_mouse_position() - position) / (size.x/(map_size.x/2.0))*2.0 - map_size/2.0)
	player.move_camera_by_minimap(cursor_pos)
