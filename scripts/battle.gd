extends Node2D

# EXP awarding
var slimeEXP = 10

# UI Node References
@onready var XPbar = %XP
@onready var LevelCounter = %Label
@onready var Turn = %Turns
@onready var attack_container = %AttackContainer # Grid/HBoxContainer holding the 4 attack buttons

# Visual Animation References
@onready var attack_sprite = $Attack_Anims/slash # Generic Sprite2D node for playing attack visuals
@onready var enemy_node = %SlimeBattle # Replace with your enemy's Sprite2D/Node2D path

# Turn & Battle State Flags
var is_player_turn: bool = true
var is_cleaning_up: bool = false

func _ready():
	update_hpbars()
	XPbar.value = GameData.experience
	XPbar.max_value = GameData.MaxXP
	LevelCounter.text = str(GameData.level)
	
	setup_attack_buttons()

func update_hpbars():
	%PlayerHealth.value = GameData.player_hp
	%EnemyHealth.value = GameData.current_enemy_hp

func setup_attack_buttons():
	if attack_container == null:
		push_error("AttackContainer node not found! Make sure it exists and uses Unique Name (%AttackContainer).")
		return

	# Clear any existing buttons
	for child in attack_container.get_children():
		child.queue_free()
		
	# Dynamically create buttons based on player's 4 equipped resources
	for attack in GameData.equipped_attacks:
		var btn = Button.new()
		btn.text = attack.name
		# Connect the button click and pass its specific AttackResource along
		btn.pressed.connect(func(): _on_attack_selected(attack))
		attack_container.add_child(btn)

func _on_attack_selected(attack: AttackResource):
	if not is_player_turn:
		print("Not ur turn >:( - Blox321")
		return

	is_player_turn = false

	# 1. Play animation dynamically using the texture stored on the attack resource
	await play_attack_animation(attack)

	# 2. Apply stats based on attack data
	if attack.heal_amount > 0:
		GameData.player_hp = min(GameData.player_hp + attack.heal_amount, GameData.max_player_hp)
		print("Healed for ", attack.heal_amount)
	
	if attack.damage > 0:
		GameData.current_enemy_hp -= attack.damage
		print("Used ", attack.name, "! Enemy took ", attack.damage, " damage.")

	update_hpbars()

	# 3. Check for battle end or pass turn
	if GameData.current_enemy_hp <= 0:
		victory()
		return

	enemy_turn()

func play_attack_animation(attack: AttackResource) -> void:
	# Skip if the AttackResource doesn't have a texture attached
	if attack.sprite_texture == null:
		print("No texture assigned to ", attack.name)
		return

	# 1. Create a dynamic Sprite2D completely from code
	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = attack.sprite_texture
	
	# Make sure it renders on top of UI/Control elements
	effect_sprite.z_index = 100 
	
	# Add the newly created sprite into the scene tree
	add_child(effect_sprite)

	# 2. Position it over the target
	if attack.heal_amount > 0:
		if has_node("%PlayerHealth"):
			effect_sprite.global_position = %PlayerHealth.global_position
	else:
		if enemy_node != null:
			effect_sprite.global_position = enemy_node.global_position
		else:
			push_error("Enemy node reference is missing!")
			effect_sprite.queue_free()
			return

	# 3. Animate the sprite using a Tween
	var tween = create_tween().set_parallel(true)
	tween.tween_property(effect_sprite, "modulate:a", 0.0, 0.4)
	tween.tween_property(effect_sprite, "scale", Vector2(2.0, 2.0), 0.4)

	# Wait for animation to finish
	await tween.finished
	
	# 4. Remove the temporary sprite from memory when done
	effect_sprite.queue_free()

func enemy_turn():
	Turn.text = "Enemy turn!"
	Turn.set("theme_override_colors/font_color", Color(1, 0, 0))
	print(GameData.enemy_type, "'s turn!")
	
	await get_tree().create_timer(2.0).timeout
	GameData.player_hp -= 5
	update_hpbars()
	print("Player received 5 damage")
	
	Turn.text = "Your turn!"
	Turn.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	is_player_turn = true

func victory():
	if is_cleaning_up:
		return
	is_cleaning_up = true
	
	if GameData.enemy_type == "Slime":
		var xp_tween = XPbar.add_xp_animated(slimeEXP)
		LevelCounter.text = str(GameData.level)
		
		print("Player's current XP is ", GameData.experience)
		print("Player's maxXP is ", GameData.MaxXP)
		
		await xp_tween.finished

	GlobalCalls.battleEnd.emit()
	GameData.defeated_enemies.append(GameData.current_enemy_id)
	
	var tree = Engine.get_main_loop() as SceneTree
	if tree:
		tree.change_scene_to_file("res://Main.tscn")

func _on_heal_pressed() -> void:
	# Legacy button handler fallback
	GameData.player_hp = min(GameData.player_hp + 10, GameData.max_player_hp)
	update_hpbars()
