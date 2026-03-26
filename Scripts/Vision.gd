extends Node3D

## Vision.gd — manages fog of war for one player.
##
## What changed from the original:
##   - interpolate_fog_image() is GONE. The per-frame GDScript pixel loop
##     that lerped 22,500 pixels every frame has been removed entirely.
##   - Fading is now handled by FogNextPass.gdshader using two texture
##     uniforms: fog_texture (current state) and fog_texture_prev (last state).
##     The shader lerps between them using a time uniform that resets on
##     each vision update. Zero CPU cost.
##   - GDScript now only uploads a texture when vision actually changes
##     (on the timer tick), not every frame.
##   - Ray count increased from 26 to 64 for cleaner vision edges.

var pre_circle_image = preload("res://Assets/2D/Shaders/map_fog_player_mask.png")

@onready var player           := get_parent()
@onready var update_fog_timer := $UpdateFog

var generated_data : Dictionary

var current_fog_map  : Image       ## Current fully-computed vision state
var previous_fog_map : Image       ## State from the previous tick — shader lerps from this

const FOG_RESOLUTION  = 1
const FOG_TEXTURE_SIZE = Vector2i(int(Basics.MAP_SIZE.x), int(Basics.MAP_SIZE.y)) * FOG_RESOLUTION
const FOG_PLAYER_SIZE  = 20 * FOG_RESOLUTION
const FOG_BEACON_SIZE  = 10 * FOG_RESOLUTION
const FOG_BASE_SIZE    = 48 * FOG_RESOLUTION

## How long the shader takes to fade between previous and current fog state.
## Matches the update_fog_timer interval for a seamless transition.
const FOG_FADE_DURATION := 0.3

var _fade_elapsed : float = 0.0
var _fading       : bool  = false

# ── Init ──────────────────────────────────────────────────────────────────────

func initialize_fog(data : Dictionary) -> void:
	generated_data = data

	current_fog_map  = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	previous_fog_map = Image.create(FOG_TEXTURE_SIZE.x, FOG_TEXTURE_SIZE.y, false, Image.FORMAT_RGBA8)
	current_fog_map.fill(Color(1.0, 1.0, 1.0))
	previous_fog_map.fill(Color(1.0, 1.0, 1.0))

	player.hud.mini_map.initialize_fog_display(
		generated_data["bases"], FOG_BASE_SIZE, FOG_PLAYER_SIZE, FOG_TEXTURE_SIZE
	)

	update_fog()
	update_fog_timer.start()

# ── Per-frame: only drives the shader fade timer ──────────────────────────────

func _process(delta: float) -> void:
	if not _fading:
		return
	_fade_elapsed = min(_fade_elapsed + delta, FOG_FADE_DURATION)
	var t := _fade_elapsed / FOG_FADE_DURATION
	_get_fog_material().set_shader_parameter("fog_fade_t", t)
	if _fade_elapsed >= FOG_FADE_DURATION:
		_fading = false

# ── Vision update (called by timer, not every frame) ─────────────────────────

func update_fog() -> void:
	# Save current as previous before overwriting
	previous_fog_map.copy_from(current_fog_map)

	# Recompute current vision state
	current_fog_map.fill(Color(1.0, 1.0, 1.0))

	# Bases are always visible
	for base_pos in generated_data["bases"]:
		_stamp_circle(current_fog_map, world_to_fog_position(base_pos), FOG_BASE_SIZE)

	# Beacons
	for beacon in player.world.beacons.get_children():
		var pos := world_to_fog_position(Vector2(beacon.global_position.x, beacon.global_position.z))
		_stamp_circle(current_fog_map, pos, FOG_BEACON_SIZE)

	# Temp vision nodes (player sight rays land here)
	for temp_v in player.world.temp_vision.get_children():
		var pos := world_to_fog_position(Vector2(temp_v.global_position.x, temp_v.global_position.z))
		_stamp_circle(current_fog_map, pos, int(temp_v.radius))

	# Upload both textures to shader — shader handles the lerp
	var mat := _get_fog_material()
	mat.set_shader_parameter("fog_texture",      ImageTexture.create_from_image(current_fog_map))
	mat.set_shader_parameter("fog_texture_prev", ImageTexture.create_from_image(previous_fog_map))

	# Reset fade
	_fade_elapsed = 0.0
	_fading       = true
	mat.set_shader_parameter("fog_fade_t", 0.0)

	# Minimap and entity visibility still driven from current_fog_map
	player.hud.mini_map.update_fog_display(current_fog_map, player.global_position)
	player.world.vision_update(self, current_fog_map)

# ── Vision queries ────────────────────────────────────────────────────────────

func has_vision(pos : Vector2i) -> bool:
	var fog_pos := world_to_fog_position(Vector2(pos)).clamp(
		Vector2i(0, 0), FOG_TEXTURE_SIZE - Vector2i(1, 1)
	)
	return current_fog_map.get_pixel(fog_pos.x, fog_pos.y).r < 0.5

# ── Player vision raycasting ──────────────────────────────────────────────────

const RAY_NUM    := 64    ## Increased from 26 — cleaner vision edges
const V_PER_RAY  := 10
const RAY_LENGTH := 12.0

func update_player_vision() -> void:
	clear_temp_vision()
	for i in range(RAY_NUM):
		var direction := Vector3.FORWARD.rotated(Vector3.UP, PI * 2.0 * (float(i) / float(RAY_NUM)))
		var length    := _vision_raycast(direction)
		for v in range(int(round(length / RAY_LENGTH * V_PER_RAY))):
			_spawn_temp_vision(
				global_position + direction * (RAY_LENGTH / float(V_PER_RAY)) * v,
				7.0
			)

func _vision_raycast(direction : Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.new()
	ray.from           = player.global_position
	ray.to             = player.global_position + direction * RAY_LENGTH
	ray.collision_mask = int(pow(2, 1-1)) + int(pow(2, 4-1))
	var result := get_world_3d().direct_space_state.intersect_ray(ray)
	if not result.is_empty():
		return player.position.distance_to(result["position"])
	return RAY_LENGTH

# ── Helpers ───────────────────────────────────────────────────────────────────

var _circle_cache : Dictionary = {}  ## size -> Image cache, avoids repeated resize

func _stamp_circle(target : Image, center : Vector2i, size : int) -> void:
	if not _circle_cache.has(size):
		var img := pre_circle_image.duplicate()
		img.resize(size, size, Image.INTERPOLATE_NEAREST)
		_circle_cache[size] = img
	var circle : Image = _circle_cache[size]
	var dest   := center - Vector2i(Vector2i(circle.get_width(), circle.get_height()) / 2.0)
	target.blend_rect(circle, circle.get_used_rect(), dest)

func world_to_fog_position(pos : Vector2) -> Vector2i:
	return Vector2i((pos + Basics.MAP_SIZE / 2.0) * FOG_RESOLUTION)

func _get_fog_material() -> ShaderMaterial:
	return player.world.fog_plane.mesh.material as ShaderMaterial

var pre_temp_vision := preload("res://Scenes/Systems/temp_vision.tscn")

func _spawn_temp_vision(vision_pos : Vector3, radius : float) -> void:
	var node := pre_temp_vision.instantiate()
	node.position = vision_pos
	node.radius   = radius
	player.world.temp_vision.add_child(node)

func clear_temp_vision() -> void:
	for temp_v in player.world.temp_vision.get_children():
		temp_v.queue_free()

# ── Timer callback ────────────────────────────────────────────────────────────

func _on_update_fog_timeout() -> void:
	update_player_vision()
	update_fog()
