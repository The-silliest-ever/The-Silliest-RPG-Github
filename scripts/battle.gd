extends Node2D

# UI Node References
@onready var XPbar = %XP
@onready var LevelCounter = %Label
@onready var Turn = %Turns
@onready var attack_container = %AttackContainer 
@onready var enemy_health_bar = %EnemyHealth

# Visual Animation References
@onready var attack_sprite = $Attack_Anims/slash 
@onready var enemy_node = %Enemy 

var is_player_turn: bool = true
var is_cleaning_up: bool = false
var active_enemy: EnemyResource

var player_statuses: Array[Dictionary] = []
var enemy_statuses: Array[Dictionary] = []

var player_stats = {
	StatModifier.StatType.ATTACK: 0,
	StatModifier.StatType.DEFENSE: 0,
	StatModifier.StatType.SPECIAL_ATTACK: 0,
	StatModifier.StatType.SPECIAL_DEFENSE: 0
}

var enemy_stats = {
	StatModifier.StatType.ATTACK: 0,
	StatModifier.StatType.DEFENSE: 0,
	StatModifier.StatType.SPECIAL_ATTACK: 0,
	StatModifier.StatType.SPECIAL_DEFENSE: 0
}

func _ready():
	active_enemy = GameData.current_enemy
	
	setup_enemy_visuals()
	update_hpbars(false) 
	
	XPbar.value = GameData.experience
	XPbar.max_value = GameData.MaxXP
	LevelCounter.text = str(GameData.level)
	
	setup_attack_buttons()
	start_player_turn()

func setup_enemy_visuals():
	if active_enemy == null:
		push_error("No EnemyResource assigned to GameData.current_enemy!")
		return

	if enemy_node is Sprite2D or enemy_node is TextureRect:
		enemy_node.texture = active_enemy.Sprite

func update_hpbars(animate: bool = true):
	%PlayerHealth.max_value = GameData.player_maxHP
	enemy_health_bar.max_value = active_enemy.MaxHP
	
	if animate:
		var tween = create_tween().set_parallel(true)
		tween.tween_property(%PlayerHealth, "value", GameData.player_hp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(enemy_health_bar, "value", GameData.current_enemy_hp, 0.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	else:
		%PlayerHealth.value = GameData.player_hp
		enemy_health_bar.value = GameData.current_enemy_hp
	
func play_attack_animation(attack: AttackResource, target_node) -> void:
	if attack == null or attack.sprite_texture == null:
		return

	var effect_sprite = Sprite2D.new()
	effect_sprite.texture = attack.sprite_texture
	effect_sprite.z_index = 100 
	add_child(effect_sprite)

	if target_node != null:
		effect_sprite.global_position = target_node.global_position
	else:
		effect_sprite.queue_free()
		return

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

func get_stat_multiplier(stage: int) -> float:
	if stage > 0:
		return 1.0 + (stage * 0.25)
	elif stage < 0:
		return 1.0 / (1.0 + abs(stage) * 0.25)
	return 1.0

func check_dodge(target: String) -> bool:
	var statuses = player_statuses if target == "player" else enemy_statuses
	var base_dodge = 0.0
	
	if target == "enemy":
		base_dodge = active_enemy.dodge_chance
	else:
		base_dodge = 5.0 
	
	for status in statuses:
		if status.type == StatusEffectData.StatusType.GROOVY:
			base_dodge += 20.0
			break
			
	var roll = randf_range(0.0, 100.0)
	if roll < base_dodge:
		return true 
		
	return false

# --- MULTI-STAT MODIFIER LOGIC ---
func apply_stat_changes(caster: String, attack: AttackResource):
	var target_stats_dict = enemy_stats if caster == "player" else player_stats
	var self_stats_dict = player_stats if caster == "player" else enemy_stats
	
	var target_name = active_enemy.Name if caster == "player" else "Player"
	var self_name = "Player" if caster == "player" else active_enemy.Name
	var stat_names = StatModifier.StatType.keys()

	# Apply Target Buffs
	for mod in attack.buffs_target:
		if mod and mod.stat != StatModifier.StatType.NONE:
			target_stats_dict[mod.stat] = min(6, target_stats_dict[mod.stat] + mod.stages)
			print(target_name, "'s ", stat_names[mod.stat], " rose by ", mod.stages, " stage(s)!")

	# Apply Target Debuffs
	for mod in attack.debuffs_target:
		if mod and mod.stat != StatModifier.StatType.NONE:
			target_stats_dict[mod.stat] = max(-6, target_stats_dict[mod.stat] - mod.stages)
			print(target_name, "'s ", stat_names[mod.stat], " fell by ", mod.stages, " stage(s)!")

	# Apply Self Buffs
	for mod in attack.buffs_self:
		if mod and mod.stat != StatModifier.StatType.NONE:
			self_stats_dict[mod.stat] = min(6, self_stats_dict[mod.stat] + mod.stages)
			print(self_name, "'s ", stat_names[mod.stat], " rose by ", mod.stages, " stage(s)!")

	# Apply Self Debuffs
	for mod in attack.debuffs_self:
		if mod and mod.stat != StatModifier.StatType.NONE:
			self_stats_dict[mod.stat] = max(-6, self_stats_dict[mod.stat] - mod.stages)
			print(self_name, "'s ", stat_names[mod.stat], " fell by ", mod.stages, " stage(s)!")
# ---------------------------------

# --- MULTI-STATUS EFFECT LOGIC ---
func apply_attack_statuses(caster: String, attack: AttackResource):
	var target_array = enemy_statuses if caster == "player" else player_statuses
	var self_array = player_statuses if caster == "player" else enemy_statuses
	var target_name = active_enemy.Name if caster == "player" else "Player"
	var self_name = "Player" if caster == "player" else active_enemy.Name
	
	for s_data in attack.target_statuses:
		if s_data and s_data.type != StatusEffectData.StatusType.NONE:
			target_array.append({
				"type": s_data.type,
				"duration": s_data.duration,
				"value": s_data.value
			})
			print(target_name, " was afflicted with status type: ", s_data.type)

	for s_data in attack.self_statuses:
		if s_data and s_data.type != StatusEffectData.StatusType.NONE:
			self_array.append({
				"type": s_data.type,
				"duration": s_data.duration,
				"value": s_data.value
			})
			print(self_name, " gained status type: ", s_data.type)
# ---------------------------------

func process_statuses(target: String) -> bool:
	var statuses = player_statuses if target == "player" else enemy_statuses
	var skip_turn = false
	var target_name = "Player" if target == "player" else active_enemy.Name
	
	for i in range(statuses.size() - 1, -1, -1):
		var status = statuses[i]
		
		match status.type:
			StatusEffectData.StatusType.POISON, StatusEffectData.StatusType.BURN:
				if target == "enemy":
					GameData.current_enemy_hp -= status.value
				else:
					GameData.player_hp -= status.value
				print(target_name, " took ", status.value, " damage from a status!")
			StatusEffectData.StatusType.GROOVY:
				print(target_name, " is feeling groovy!")
				
		status.duration -= 1
		if status.duration <= 0:
			print(target_name, " recovered from their status effect.")
			statuses.remove_at(i)
			
	update_hpbars() 
	return skip_turn

func start_player_turn():
	is_player_turn = false 
	var skip = process_statuses("player")
	
	if GameData.player_hp < 1:
		print("Player succumbed to status effects!")
		get_tree().quit()
		return
		
	if skip:
		await get_tree().create_timer(1.0).timeout
		enemy_turn()
		return
		
	Turn.text = "Your turn!"
	Turn.set("theme_override_colors/font_color", Color(1.0, 1.0, 1.0, 1.0))
	is_player_turn = true

func _on_attack_selected(attack: AttackResource):
	if not is_player_turn:
		return
	is_player_turn = false

	await play_attack_animation(attack, enemy_node)

	if check_dodge("enemy"):
		print(active_enemy.Name, " dodged the attack!")
		update_hpbars()
		enemy_turn()
		return

	if attack.heal_amount > 0:
		GameData.player_hp = min(GameData.player_hp + attack.heal_amount, GameData.player_maxHP)
	
	if attack.damage > 0:
		var atk_mod = get_stat_multiplier(player_stats[StatModifier.StatType.ATTACK])
		var def_mod = get_stat_multiplier(enemy_stats[StatModifier.StatType.DEFENSE])
		
		var effective_damage = int(attack.damage * atk_mod)
		var effective_defense = int(active_enemy.Defense_stat * def_mod)
		
		var calculated_damage = max(1, effective_damage - int(effective_defense * 0.1))
		GameData.current_enemy_hp -= calculated_damage
		print("Used ", attack.name, "! ", active_enemy.Name, " took ", calculated_damage, " damage.")

	apply_attack_statuses("player", attack)
	apply_stat_changes("player", attack)
	
	update_hpbars() 

	if GameData.current_enemy_hp <= 0:
		victory()
		return

	enemy_turn()

func enemy_turn():
	Turn.text = active_enemy.Name + "'s turn!"
	Turn.set("theme_override_colors/font_color", Color(1, 0, 0))
	
	await get_tree().create_timer(1.0).timeout
	
	var skip = process_statuses("enemy")
	
	if GameData.current_enemy_hp <= 0:
		victory()
		return
		
	if skip:
		await get_tree().create_timer(1.0).timeout
		start_player_turn()
		return
	
	if active_enemy.attacks.size() > 0:
		var chosen_attack: AttackResource = active_enemy.attacks.pick_random()
		await play_attack_animation(chosen_attack, %PlayerHealth)
		
		if check_dodge("player"):
			print("Player dodged ", active_enemy.Name, "'s attack!")
			update_hpbars()
			start_player_turn()
			return
		
		var atk_mod = get_stat_multiplier(enemy_stats[StatModifier.StatType.ATTACK])
		var def_mod = get_stat_multiplier(player_stats[StatModifier.StatType.DEFENSE])
		
		var base_dmg = chosen_attack.damage if chosen_attack.damage > 0 else 5
		var effective_attack = int(active_enemy.Physical_stat * atk_mod)
		
		var total_damage = max(1, int((base_dmg + int(effective_attack * 0.2)) / def_mod))
		
		GameData.player_hp = max(0, GameData.player_hp - total_damage)
		print(active_enemy.Name, " used ", chosen_attack.name, " dealing ", total_damage, " damage.")
		
		apply_attack_statuses("enemy", chosen_attack)
		apply_stat_changes("enemy", chosen_attack)
		
	else:
		if check_dodge("player"):
			print("Player dodged ", active_enemy.Name, "'s attack!")
			update_hpbars()
			start_player_turn()
			return
			
		GameData.player_hp = max(0, GameData.player_hp - 5)
		print(active_enemy.name, " attacked for 5 damage.")

	update_hpbars() 
	
	if GameData.player_hp < 1:
		print("Player has lost a battle")
		get_tree().quit()
	else:
		start_player_turn()

func victory():
	if is_cleaning_up:
		return
	is_cleaning_up = true
	
	var xp_reward = active_enemy.XPReward if active_enemy else 10
	var xp_tween = XPbar.add_xp_animated(xp_reward)
	LevelCounter.text = str(GameData.level)
	
	await xp_tween.finished

	GlobalCalls.battleEnd.emit()
	GameData.defeated_enemies.append(GameData.current_enemy_id)
	
	get_tree().change_scene_to_file("res://Main.tscn")
