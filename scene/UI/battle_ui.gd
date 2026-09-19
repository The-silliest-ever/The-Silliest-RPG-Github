extends Control

signal action_selected(action_type, attack_resource, target)

@onready var member_label = $Player
@onready var attack_container = $AttackContainer 

const battleScript = preload("res://scene/3d/3d_battle.gd")

# --- NEW VARIABLES FOR TARGETING ---
var active_enemies: Array = []
var pending_attack = null
var target_buttons_map: Dictionary = {} # Links the UI button to the 3D enemy
# -----------------------------------

# Add these @onready variables near the top of battle_ui.gd
@onready var enemy_hp_bar_1 = $Enemy1hp
@onready var enemy_hp_label_1 = $Enemy1hp/whoisyou
@onready var enemy_hp_bar_2 = $Enemy2hp
@onready var enemy_hp_label_2 = $Enemy2hp/whoisyou2

func _ready():
	# Hide them by default until a battle starts
	enemy_hp_bar_1.hide()
	enemy_hp_bar_2.hide()
	

# Call this to update values and show the bar
func update_enemy_hp(index: int, current_hp: int, max_hp: int, enemy_name: String):
	if index == 0:
		enemy_hp_bar_1.max_value = max_hp
		enemy_hp_bar_1.value = current_hp
		enemy_hp_label_1.text = enemy_name
		enemy_hp_bar_1.show()
	elif index == 1:
		enemy_hp_bar_2.max_value = max_hp
		enemy_hp_bar_2.value = current_hp
		enemy_hp_label_2.text = enemy_name
		enemy_hp_bar_2.show()
		
	%PlayerHealth.value = GameData.player_hp
	%PlayerHealth.max_value = GameData.player_maxHP
	%"2ndPartyHealth2".value = GameData.partymemembrHP
	%"2ndPartyHealth2".max_value = GameData.partmembrMaxHP
	_updateHP()

# Call this when an enemy dies so their bar disappears
func hide_enemy_hp(index: int):
	if index == 0:
		enemy_hp_bar_1.hide()
	elif index == 1:
		enemy_hp_bar_2.hide()

# Call this from Main Battle when the fight starts
func setup_enemies(enemies_in_battle: Array):
	active_enemies = enemies_in_battle

func Make_attack_menu(current_member):
	attack_container.show() # Make sure the menu is visible
	
	for child in attack_container.get_children():
		child.queue_free()
		
	if current_member == null: return
		
	for attack in current_member.equipped_attacks:
		if attack == null: continue
			
		var btn = Button.new()
		btn.text = attack.name
		btn.pressed.connect(func(): _on_attack_button_pressed(attack))
		attack_container.add_child(btn)

func _on_attack_button_pressed(chosen_attack):
	# 1. Save the attack into memory
	pending_attack = chosen_attack
	
	# 2. Hide the attack menu so the screen isn't cluttered
	attack_container.hide()
	
	# 3. Spawn the target buttons over the enemies
	_spawn_target_buttons()

func _spawn_target_buttons():
	for enemy in active_enemies:
		var btn = Button.new()
		btn.text = "Target"
		
		# Connect the target button to the final execution step
		btn.pressed.connect(func(): _on_target_selected(enemy))
		
		add_child(btn)
		
		# Add to dictionary so we can update its position in _process
		target_buttons_map[btn] = enemy

# This keeps the 2D buttons glued to the 3D enemies every frame
func _process(_delta):
	if target_buttons_map.is_empty():
		return
		
	var camera = get_viewport().get_camera_3d()
	
	for btn in target_buttons_map:
		var enemy = target_buttons_map[btn]
		
		# Get the 3D position of the marker above the enemy's head
		var pos_3d = enemy.get_node("TargetAnchor").global_position
		
		# Unproject translates that 3D spot into a 2D screen coordinate!
		btn.position = camera.unproject_position(pos_3d)

func _on_target_selected(enemy):
	# 1. Clear out the target buttons
	for btn in target_buttons_map:
		btn.queue_free()
	target_buttons_map.clear()
	
	# 2. Emit the final signal with the saved attack AND the chosen enemy
	action_selected.emit("attack", pending_attack, enemy)
	
	# 3. Clear memory
	pending_attack = null
	
func update_member_display(member_name: String):
	if member_label:
		member_label.text = member_name

func _updateHP():
	print("I will tweeeeeeeen rn")
	%PlayerHealth.update_bar(GameData.current_enemy_hp)
	%"2ndPartyHealth2".update_bar(GameData.current_enemy_hp2)
	%Enemy1hp.update_bar(GameData.current_enemy_hp)
	%Enemy2hp.update_bar(GameData.current_enemy_hp2)
