extends PanelContainer

var stat : Stat
var stat_value

func _ready():
	$MarginCont/StatIcon.texture = stat.icon
	$MarginCont/StatLabel.text = str(int(stat_value))
