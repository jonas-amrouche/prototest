extends RichTextLabel

var passive : Passive

func _ready():
	if passive:
		text = "[i][color=#"+str(passive.color.to_html())+"]" + passive.id.capitalize() + "[/color] [color=#B7B7B7]: " + \
		passive.description + "[/color][/i]"
		
