extends Panel

var level : int
var level_progress : int

@onready var level_lab = $LevelContainer/InnerCont/LevelTitle/LevelLab
@onready var level_progress_lab = $LevelContainer/InnerCont/LevelTitle/LevelProgressLab

func _ready():
	level_lab.set_text("Level " + str(level))
	level_progress_lab.set_text(str(min(level, 16)) + "/" + str(level_progress))
