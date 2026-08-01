extends Control

func _ready() -> void:
	%Play.pressed.connect(play)
	%Quit.pressed.connect(quit_game)

func play():
	get_tree().change_scene_to_file(
		'res://Main.tscn'
	)

func quit_game():
	get_tree().quit()
