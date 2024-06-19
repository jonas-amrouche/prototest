extends Control

func _ready():
	pass

func _process(delta):
	pass

func _on_close_pressed():
	get_tree().quit()

func _on_minimize_pressed():
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
