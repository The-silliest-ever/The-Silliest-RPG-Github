extends Node3D

@onready var battle_ui = $BattleUi

# Reference the Marker3D nodes you placed in the scene
@onready var spawn_points = [$spawn1, $spawn2]

var active_enemies_in_battle: Array = [] 
signal updateBars()

func _ready():
	battle_ui.action_selected.connect(_execute_turn)
	
	updateBars.connect(battle_ui._updateHP)
	
	_load_encountered_enemies()
	battle_ui.setup_enemies(active_enemies_in_battle)
	
	var current_player = GameData.active_party[0]
	if current_player != null:
		battle_ui.Make_attack_menu(current_player)
		battle_ui.update_member_display(current_player.name)

func _load_encountered_enemies():
	if GameData.current_enemy != null and GameData.current_enemy.strippedScene != null:
		var enemy_instance = GameData.current_enemy.strippedScene.instantiate()
		add_child(enemy_instance)
		enemy_instance.global_position = spawn_points[0].global_position
		active_enemies_in_battle.append(enemy_instance)
		
		# INITIALIZE THE HEALTH BAR DISPLAY FOR ENEMY 1
		# (Assuming your EnemyResource has a 'max_hp' and a 'name' property)
		var max_hp = GameData.current_enemy.max_hp if "max_hp" in GameData.current_enemy else 100
		GameData.current_enemy_hp = max_hp # Set starting HP
		
		battle_ui.update_enemy_hp(0, GameData.current_enemy_hp, max_hp, GameData.current_enemy.Name)
	else:
		push_error("No enemy resource found!")

func _execute_turn(action_type, attack_resource, target):
	if action_type == "attack":
		var enemy_index = active_enemies_in_battle.find(target)
		var damage_dealt = attack_resource.damage 
		
		if enemy_index == 0:
			GameData.current_enemy_hp -= damage_dealt
			
			# UPDATE THE VISUAL HEALTH BAR
			updateBars.emit()
			
			if GameData.current_enemy_hp <= 0:
				battle_ui.hide_enemy_hp(0)
				_defeat_enemy(target, enemy_index)
				
		elif enemy_index == 1:
			GameData.current_enemy_hp2 -= damage_dealt
			
			# UPDATE THE VISUAL HEALTH BAR FOR ENEMY 2 (Repeat structure if using second enemy resource)
			
			if GameData.current_enemy_hp2 <= 0:
				battle_ui.hide_enemy_hp(1)
				_defeat_enemy(target, enemy_index)
		
		if active_enemies_in_battle.size() > 0:
			await get_tree().create_timer(1.0).timeout
			_enemy_turn()
		else:
			print("You win the battle!")

func _defeat_enemy(enemy_node, index):
	active_enemies_in_battle.erase(enemy_node)
	enemy_node.queue_free()
	print("Enemy defeated!")

func _enemy_turn():
	print("Enemy is attacking the player!")
	
	# Simple enemy damage value (you can pull this from GameData.current_enemy later)
	var enemy_damage = 10 
	
	GameData.player_hp -= enemy_damage
	print("Player HP left: ", GameData.player_hp)
	
	if GameData.player_hp <= 0:
		print("Game Over!")
		# Handle player defeat here
	else:
		# Hand the turn back to the player: refresh the attack menu
		var current_player = GameData.active_party[0]
		if current_player != null:
			battle_ui.Make_attack_menu(current_player)
