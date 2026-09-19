extends CanvasLayer

@onready var color_rect = $BlckScrn
@onready var label = $L

func _ready():
	color_rect.modulate.a = 0.0
	label.modulate.a = 0.0
	hide()

func fade_in():
	print("okay im showing the dead screen now!!11!1!")
	show()
	var tween = create_tween().set_parallel(true)
	tween.tween_property(color_rect, "modulate:a", 1.0, 1.5)
	tween.tween_property(label, "modulate:a", 1.0, 1.5)
