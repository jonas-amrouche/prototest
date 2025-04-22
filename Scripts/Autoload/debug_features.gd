extends Node

func _ready() -> void:
	AudioServer.set_bus_volume_db(0, -100.0)

func _physics_process(_delta: float) -> void:
	if !OS.is_debug_build():
		set_physics_process(false)
		return
	
	var _player = get_tree().get_first_node_in_group("player")
	if Input.is_action_just_pressed("debug_quit_game"):
		get_tree().quit()
	if Input.is_action_just_pressed("debug_fullscreen"):
		match DisplayServer.window_get_mode():
			DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
			DisplayServer.WINDOW_MODE_WINDOWED: DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN)
	if Input.is_action_just_pressed("debug_hide_ui"):
		_player.hud.set_visible(!_player.hud.visible)
	if Input.is_action_just_pressed("debug_free_mouse"):
		match DisplayServer.mouse_get_mode():
			DisplayServer.MOUSE_MODE_CONFINED: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
			DisplayServer.MOUSE_MODE_VISIBLE: DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_CONFINED)
	if Input.is_action_just_pressed("debug_mute"):
		if AudioServer.get_bus_volume_db(0) == -100.0:
			AudioServer.set_bus_volume_db(0, 0.0)
		else:
			AudioServer.set_bus_volume_db(0, -100.0)

func debug_box(parent : Object, pos : Vector3, size : float = 1.0, color : Color = Color(1.0, 1.0, 1.0)) -> void:
	var _box = CSGBox3D.new()
	_box.position = pos
	_box.scale *= size
	_box.material = StandardMaterial3D.new()
	_box.material.albedo_color = color
	parent.add_child(_box)
