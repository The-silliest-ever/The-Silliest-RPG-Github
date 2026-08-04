extends Node2D

# UI Node References
@onready var XPbar = %XP
@onready var LevelCounter = %Label
@onready var Turn = %Turns
@onready var attack_container = %AttackContainer 
@onready var enemy_health_bar = %EnemyHealth

# Visual Animation References
@onready var attack_sprite = $Attack_Anims/slash 
@onready var enemy_node = %Enemy # Should be a Sprite2D or TextureRect node

var is_player_turn: bool = true
var is_cleaning_up: bool = false
var active_enemy: EnemyResource

func _ready():
	# 1. Load active enemy resource from GameData
	active_enemy = GameData.current_enemy
	
	setup_enemy_visuals()
	update_hpbars()
	
	XPbar.value = GameData.experience
	XPbar.max_value = GameData.MaxXP
	LevelCounter.text = str(GameData.level)
	
	setup_attack_buttons()

func setup_enemy_visuals():
	if active_enemy == null:
		push_error("No EnemyResource assigned to GameData.current_enemy!")
		return

	# Apply Sprite
	if enemy_node is Sprite2D or enemy_node is TextureRect:
		enemy_node.texture = active_enemy.Sprite

	# Apply Health UI Limit
	enemy_health_bar.max_value = active_enemy.MaxHP

func update_hpbars():
	%PlayerHealth.value = GameData.player_hp
	enemy_health_bar.value = GameData.current_enemy_hp
	
func play_attack_animation(attack: AttackResource, target_node) -> void:
	# Skip if the AttackResource doesn't have a texture attached
	if attack == null or attack.sprite_texture == null:
		return

	# Create sprite dynamically
	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = attack.sprite_texture
	effect_sprite.z_index = 100 
	add_child(effect_sprite)

	# Position over the specified target
	if target_node != null:
		effect_sprite.global_position = target_node.global_position
	else:
		effect_sprite.queue_free()
		return

	# Animate using Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(effect_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_property(effect_sprite, "scale", Vector2(2.0, 2.0), 0.4)

	await tween.finished
	effect_sprite.queue_free()

func setup_attack_buttons():
	if attack_container == null:
		push_error("AttackContainer node not found!")
		return

	for child in attack_container.get_children():
		child.queue_free()
		
	for attack in GameData.equipped_attacks:
		var btn = Button.new()
		btn.text = attack.name
		btn.pressed.connect(func(): _on_attack_selected(attack))
		attack_container.add_child(btn)

func _on_attack_selected(attack: AttackResource):
	if not is_player_turn:
		return

	is_player_turn = false

	await play_attack_animation(attack, enemy_node)

	# Apply attack stats against active enemy's stats
	if attack.heal_amount > 0:
		GameData.player_hp = min(GameData.player_hp + attack.heal_amount, GameData.player_maxHP)
	
	if attack.damage > 0:
		# Dynamic damage calculation factoring in enemy defense
		var calculated_damage = max(1, attack.damage - int(active_enemy.Defense_stat * 0.1))
		GameData.current_enemy_hp -= calculated_damage
		print("Used ", attack.name, "! ", active_enemy.Name, " took ", calculated_damage, " damage.")

	update_hpbars()

	if GameData.current_enemy_hp <= 0:
		victory()
		return

	enemy_turn()

func enemy_turn():
	Turn.text = active_enemy.Name + "'s turn!"
	Turn.set("theme_override_colors/font_color", Color(1, 0, 0))
	
	await get_tree().create_timer(1.5).timeout
	
	# Pick a random attack from the enemy's assigned attack array
	if active_enemy.attacks.size() > 0:
		var chosen_attack: AttackResource = active_enemy.attacks.pick_random()
		# Target is the player health bar or player sprite node
		await play_attack_animation(chosen_attack, %PlayerHealth)
		
		# Apply damage factoring in enemy's physical stat
		var base_dmg = chosen_attack.damage if chosen_attack.damage > 0 else 5
		var total_damage = base_dmg + int(active_enemy.Physical_stat * 0.2)
		
		GameData.player_hp = max(0, GameData.player_hp - total_damage)
		print(active_enemy.Name, " used ", chosen_attack.name, " dealing ", total_damage, " damage.")
	else:
		# Fallback if no attacks assigned
		GameData.player_hp = max(0, GameData.player_hp - 5)
		print(active_enemy.name, " attacked for 5 damage.")

	update_hpbars()
	
	Turn.text = "Your turn!"
	Turn.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	is_player_turn = true

func victory():
	if is_cleaning_up:
		return
	is_cleaning_up = true
	
	# Award dynamic XP stored directly on the resource
	var xp_reward = active_enemy.XPReward if active_enemy else 10
	var xp_tween = XPbar.add_xp_animated(xp_reward)
	LevelCounter.text = str(GameData.level)
	
	await xp_tween.finished

	GlobalCalls.battleEnd.emit()
	GameData.defeated_enemies.append(GameData.current_enemy_id)
	
	get_tree().change_scene_to_file("res://Main.tscn")
