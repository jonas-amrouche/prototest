extends PanelContainer

var stat_id    : String
var stat_value : int

func _ready() -> void:
	var label      := $MarginCont/StatLabel
	var icon_node  := $MarginCont/StatIcon

	# Display value
	label.text = str(stat_value)

	# Color from STAT_COLORS, white fallback
	if label.label_settings:
		label.label_settings.font_color = Basics.STAT_COLORS.get(stat_id, Color.WHITE)

	# No icon lookup needed — Stat resources are no longer required.
	# If you add stat icons later, map stat_id -> icon path here.
	icon_node.visible = false
