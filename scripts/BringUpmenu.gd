extends Button

const UI_toLoad = preload("res://scene/UI/GenMenu.tscn")

func _on_pressed() -> void:
	var ui_instance = UI_toLoad.instantiate()
	
	add_child(ui_instance)
	get_tree().paused = true
