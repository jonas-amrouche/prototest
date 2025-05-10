extends Node3D

@onready var world := get_parent().get_parent()

@export var camp : Camp

var alive := true
var camp_level : int = 1

@onready var monster_scene = world.resources.monster_scene

@onready var respawn_timer := $Respawn
@onready var camp_flames_model := $CampFireModel/CampFlames
@onready var camp_model := $CampFireModel

func _ready() -> void:
	camp_model.rotate(Vector3.UP, randf_range(-PI, PI))
	get_tree().create_timer(0.5).timeout.connect(func():
		respawn_timer.wait_time = camp.respawn_time
		spawn_monsters(camp.monsters))

func spawn_monsters(monsters : Array[Monster]) -> void:
	alive = true
	camp_flames_model.set_visible(true)
	for m in range(monsters.size()):
		var _new_monster = monster_scene.instantiate()
		_new_monster.camp = self
		_new_monster.level = camp_level
		_new_monster.monster = monsters[m]
		_new_monster.rotation = Vector3(0, randf_range(-PI, PI), 0)
		_new_monster.position = get_node("MonsterPos" + str(m+1)).position + position
		world.monsters.add_child(_new_monster)

var monster_dead := int()
func monster_died() -> void:
	monster_dead += 1
	if monster_dead >= camp.monsters.size():
		alive = false
		respawn_timer.start()
		camp_flames_model.set_visible(false)
		camp_level += 1
		monster_dead = 0

func change_camp_visibility(visi : bool) -> void:
	camp_flames_model.set_visible(alive and visi)

func _on_respawn_timeout() -> void:
	spawn_monsters(camp.monsters)
