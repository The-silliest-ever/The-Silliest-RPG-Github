extends Node3D

@onready var battle_ui = $BattleUi

func _ready():
	# 1. Call Down: Update the UI with initial data
	battle_ui.update_member_display("Member 1")
	
	# 2. Signal Up: Listen for the UI's signals
	battle_ui.action_selected.connect(_execute_turn)
	var current_player = GameData.active_party[0]
	
	if current_player != null:
		battle_ui.Make_attack_menu(current_player)
		battle_ui.update_member_display(current_player.name)
# The actual gameplay logic stays safely in the Battle System
func _execute_turn(action_type, target):
	if action_type == "attack":
		print("Calculating accuracy and damage against ", target)
