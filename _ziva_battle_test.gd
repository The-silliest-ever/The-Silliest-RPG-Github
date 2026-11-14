extends Node

func _ready() -> void:
	GameData.current_enemy = load("res://EnemyResource/Slime.tres")
	GameData.current_enemy_id = "ziva_test"
	get_tree().call_deferred("change_scene_to_file", "res://scene/3d/3dBattle.tscn")