extends Control

@onready var container: VBoxContainer = %VBoxContainer

func _ready() -> void:
	# Listen for item pickup
	GameData.item_picked_up.connect(_on_item_picked_up)

func _on_item_picked_up(item: Item) -> void:
	# 1. Create the Label
	var label = Label.new()
	label.text = "+ 1 " + item.Name 
	label.add_theme_font_size_override("font_size", 24)
	
	# 2. Add it to the VBoxContainer
	container.add_child(label)
	
	# 3. Create the Tween for fading
	var tween = create_tween()
	
	# Keep it fully visible for 2 seconds
	tween.tween_interval(2.0)
	
	# Fade the transparency (modulate:a) out over 1 second
	tween.tween_property(label, "modulate:a", 0.0, 1.0)
	
	# Delete the label once the fade is done
	tween.tween_callback(label.queue_free)
