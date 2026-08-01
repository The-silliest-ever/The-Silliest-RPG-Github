extends Node2D

@onready var player = %Player

func _ready():
	GlobalCalls.battleEnd.connect(_on_battle_ended)
	GlobalCalls.battle.connect(_on_battle_started)

func _on_battle_started():
	print("Battle started hopefuly!")
	get_tree().call_deferred("change_scene_to_file", "res://scene/Battle.tscn")

func _on_battle_ended():
	pass
