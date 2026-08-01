extends Control



func _on_exit_pressed() -> void:
	get_tree().paused = false
	queue_free()
