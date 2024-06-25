extends Node3D

@export var monster : Monster

var alive := true
var level : int = 1

@onready var respawn_timer := $Respawn
@onready var camp_flames_model := $CampFireModel/CampFlames

func _ready() -> void:
	get_tree().create_timer(0.5).timeout.connect(func():
		respawn_timer.wait_time = monster.respawn_time
		spawn_monster())

func spawn_monster() -> void:
	alive = true
	camp_flames_model.set_visible(true)
	var _new_monster = monster.monster_scene.instantiate()
	_new_monster.position = get_node("MonsterPos" + str(randi_range(1, 5))).position
	add_child(_new_monster)

func monster_died() -> void:
	alive = false
	respawn_timer.start()
	camp_flames_model.set_visible(false)
	level += 1

func _on_respawn_timeout() -> void:
	spawn_monster()
