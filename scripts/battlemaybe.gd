extends Area2D

@export var enemy_id := ""

func _on_body_entered(body):
	if body.name == "Player":
		GameData.enemy_type = "Slime"
		GameData.current_enemy_id = enemy_id
		GameData.current_enemy_hp = 20
		GlobalCalls.battle.emit()
