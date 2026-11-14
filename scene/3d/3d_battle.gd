extends Node3D

## 3D turn-based battle controller.
## Ports the stat-stage / status-effect / miss-dodge / healing system from the
## original (now removed) 2D battle into the 3D scene.

const RETURN_SCENE := "res://scene/3d/3dWorld.tscn"
const MESSAGE_DELAY := 0.7
const PLAYER_BASE_DODGE := 5.0
const STAGE_LIMIT := 6

@onready var battle_ui: BattleUI = $BattleUi
@onready var spawn_points: Array[Marker3D] = [$spawn1, $spawn2]

## Each entry: { node, resource, name, hp, max_hp, stats, statuses }.
var enemies: Array[Dictionary] = []
var player_stats: Dictionary = {}
var player_statuses: Array[Dictionary] = []

## True while an action/animation is resolving so stray input is ignored.
var _busy: bool = false


func _ready() -> void:
	battle_ui.action_selected.connect(_on_action_selected)
	player_stats = _new_stat_dict()
	_load_encountered_enemies()
	if enemies.is_empty():
		battle_ui.setup_battle([], _current_member())
		battle_ui.show_message("No enemy encountered. Your turn!")
		return
	battle_ui.setup_battle(_enemy_nodes(), _current_member())
	_begin_player_turn()


# ------------------------------------------------------------------ setup
func _current_member() -> PartyMember:
	return GameData.active_party[0] if GameData.active_party.size() > 0 else null


func _enemy_nodes() -> Array:
	var nodes: Array = []
	for enemy in enemies:
		nodes.append(enemy["node"])
	return nodes


func _new_stat_dict() -> Dictionary:
	return {
		StatModifier.StatType.ATTACK: 0,
		StatModifier.StatType.DEFENSE: 0,
		StatModifier.StatType.SPECIAL_ATTACK: 0,
		StatModifier.StatType.SPECIAL_DEFENSE: 0,
	}


func _load_encountered_enemies() -> void:
	var resource: EnemyResource = GameData.current_enemy
	if resource == null or resource.strippedScene == null:
		# Load default enemy if none set
		var default_res := load("res://EnemyResource/Slime.tres")
		if default_res == null:
			push_error("No default enemy resource found. Place EnemyResource/Slime.tres in the project.")
			return
		resource = default_res
	GameData.current_enemy = resource
	var node: Node3D = resource.strippedScene.instantiate()
	add_child(node)
	node.global_position = spawn_points[0].global_position
	var max_hp: int = resource.MaxHp
	enemies.append({
		"node": node,
		"resource": resource,
		"name": resource.Name,
		"hp": max_hp,
		"max_hp": max_hp,
		"stats": _new_stat_dict(),
		"statuses": [],
	})


# ------------------------------------------------------------------ turn flow
func _begin_player_turn() -> void:
	if _check_victory():
		return
	_tick_statuses(player_statuses, func(value: int): GameData.player_hp -= value)
	_update_all_hp()
	battle_ui.update_status_icons(player_statuses, _primary_enemy_statuses())
	if GameData.player_hp <= 0:
		_defeat()
		return
	battle_ui.show_message("Your turn!")
	_busy = false
	battle_ui.show_attack_menu()


func _on_action_selected(attack: AttackResource, target: Node3D) -> void:
	if _busy:
		return
	var enemy_index := _index_of_node(target)
	if enemy_index == -1:
		return
	_busy = true
	battle_ui.hide_attack_menu()
	await _player_attack(attack, enemy_index)
	if _check_victory():
		return
	await _enemies_turn()
	if GameData.player_hp <= 0:
		_defeat()
		return
	_begin_player_turn()


# ------------------------------------------------------------------ player
func _player_attack(attack: AttackResource, enemy_index: int) -> void:
	var enemy: Dictionary = enemies[enemy_index]
	battle_ui.show_message("Player used %s!" % attack.name)
	await _wait(MESSAGE_DELAY)

	if attack.heal_amount <= 0:
		if _roll_miss(attack):
			battle_ui.show_message("Your attack missed!", Color(0.6, 0.6, 0.6))
			await _wait(MESSAGE_DELAY)
			return
		if _roll_dodge(enemy["resource"].dodge_chance, enemy["statuses"]):
			battle_ui.show_message("%s dodged the attack!" % enemy["name"], Color(1.0, 0.8, 0.2))
			await _wait(MESSAGE_DELAY)
			return

	if attack.heal_amount > 0:
		GameData.player_hp = mini(GameData.player_hp + attack.heal_amount, GameData.player_maxHP)

	if attack.damage > 0:
		var damage := _calculate_damage(
			player_stats, enemy["stats"], attack, _enemy_defense(enemy["resource"], attack)
		)
		_damage_enemy(enemy_index, damage)

	_apply_statuses(attack.target_statuses, enemy["statuses"])
	_apply_statuses(attack.self_statuses, player_statuses)
	_apply_stat_changes(attack, enemy["stats"], player_stats)

	_update_all_hp()
	battle_ui.update_status_icons(player_statuses, _primary_enemy_statuses())

	if enemy["hp"] <= 0:
		await _defeat_enemy(enemy_index)


# ------------------------------------------------------------------ enemy
func _enemies_turn() -> void:
	for i in range(enemies.size()):
		if GameData.player_hp <= 0:
			return
		var enemy: Dictionary = enemies[i]
		if enemy["hp"] <= 0:
			continue
		# Damage-over-time statuses tick at the start of the enemy's turn.
		_tick_statuses(enemy["statuses"], func(value: int): _damage_enemy(i, value))
		_update_all_hp()
		battle_ui.update_status_icons(player_statuses, _primary_enemy_statuses())
		if enemy["hp"] <= 0:
			await _defeat_enemy(i)
			continue
		await _enemy_attack(enemy)
		if GameData.player_hp <= 0:
			return


func _enemy_attack(enemy: Dictionary) -> void:
	var resource: EnemyResource = enemy["resource"]
	var attack: AttackResource = null
	if resource.attacks.size() > 0:
		attack = resource.attacks.pick_random()

	battle_ui.show_message("%s's turn!" % enemy["name"], Color(1.0, 0.35, 0.35))
	await _wait(MESSAGE_DELAY)

	if attack == null:
		GameData.player_hp = maxi(0, GameData.player_hp - 5)
		_update_all_hp()
		return

	if attack.heal_amount <= 0:
		if _roll_miss(attack):
			battle_ui.show_message("%s's attack missed!" % enemy["name"], Color(0.6, 0.6, 0.6))
			await _wait(MESSAGE_DELAY)
			return
		if _roll_dodge(PLAYER_BASE_DODGE, player_statuses):
			battle_ui.show_message("Player dodged the attack!", Color(0.2, 0.8, 1.0))
			await _wait(MESSAGE_DELAY)
			return

	if attack.heal_amount > 0:
		enemy["hp"] = mini(enemy["max_hp"], enemy["hp"] + attack.heal_amount)

	if attack.damage > 0:
		var damage := _calculate_damage(enemy["stats"], player_stats, attack, GameData.defense)
		GameData.player_hp = maxi(0, GameData.player_hp - damage)

	_apply_statuses(attack.target_statuses, player_statuses)
	_apply_statuses(attack.self_statuses, enemy["statuses"])
	_apply_stat_changes(attack, player_stats, enemy["stats"])

	_update_all_hp()
	battle_ui.update_status_icons(player_statuses, _primary_enemy_statuses())


# ------------------------------------------------------------------ combat maths
func _calculate_damage(
	attacker_stats: Dictionary, defender_stats: Dictionary, attack: AttackResource, defender_defense: float
) -> int:
	var attack_mod := _stat_multiplier(attacker_stats[StatModifier.StatType.ATTACK])
	var defense_mod := _stat_multiplier(defender_stats[StatModifier.StatType.DEFENSE])
	var effective_damage := int(attack.damage * attack_mod)
	var effective_defense := int(defender_defense * defense_mod)
	return maxi(1, effective_damage - int(effective_defense * 0.1))


func _enemy_defense(resource: EnemyResource, attack: AttackResource) -> float:
	if attack.type == AttackResource.AttackCategory.SPECIAL:
		return resource.Special_Defense_stat
	return resource.Defense_stat


func _stat_multiplier(stage: int) -> float:
	if stage > 0:
		return 1.0 + stage * 0.25
	if stage < 0:
		return 1.0 / (1.0 + absi(stage) * 0.25)
	return 1.0


func _roll_miss(attack: AttackResource) -> bool:
	if attack == null or attack.miss_chance <= 0:
		return false
	return randf() * 100.0 < attack.miss_chance


func _roll_dodge(base_dodge: float, statuses: Array) -> bool:
	var dodge := base_dodge
	for status in statuses:
		if status["type"] == StatusEffectData.StatusType.GROOVY:
			dodge += 20.0
			break
	return randf() * 100.0 < dodge


# ------------------------------------------------------------------ effects
func _apply_statuses(new_statuses: Array, target: Array) -> void:
	for data in new_statuses:
		if data == null or data.type == StatusEffectData.StatusType.NONE:
			continue
		target.append({"type": data.type, "duration": data.duration, "value": data.value})


func _apply_stat_changes(attack: AttackResource, target_stats: Dictionary, self_stats: Dictionary) -> void:
	for mod in attack.buffs_target:
		_shift_stage(target_stats, mod, 1)
	for mod in attack.debuffs_target:
		_shift_stage(target_stats, mod, -1)
	for mod in attack.buffs_self:
		_shift_stage(self_stats, mod, 1)
	for mod in attack.debuffs_self:
		_shift_stage(self_stats, mod, -1)


func _shift_stage(stats: Dictionary, mod: StatModifier, direction: int) -> void:
	if mod == null or mod.stat == StatModifier.StatType.NONE:
		return
	stats[mod.stat] = clampi(stats[mod.stat] + mod.stages * direction, -STAGE_LIMIT, STAGE_LIMIT)


func _tick_statuses(statuses: Array, on_damage: Callable) -> void:
	for i in range(statuses.size() - 1, -1, -1):
		var status: Dictionary = statuses[i]
		if status["type"] == StatusEffectData.StatusType.BURN or status["type"] == StatusEffectData.StatusType.POISON:
			on_damage.call(int(status["value"]))
		status["duration"] = int(status["duration"]) - 1
		if status["duration"] <= 0:
			statuses.remove_at(i)


# ------------------------------------------------------------------ helpers
func _damage_enemy(index: int, amount: int) -> void:
	var enemy: Dictionary = enemies[index]
	enemy["hp"] = maxi(0, enemy["hp"] - amount)


func _update_all_hp() -> void:
	for i in range(enemies.size()):
		var enemy: Dictionary = enemies[i]
		if enemy["hp"] > 0:
			battle_ui.update_enemy_hp(i, enemy["hp"], enemy["max_hp"], enemy["name"])
	if not enemies.is_empty():
		GameData.current_enemy_hp = enemies[0]["hp"]
	battle_ui.refresh_bars()


func _primary_enemy_statuses() -> Array:
	return enemies[0]["statuses"] if not enemies.is_empty() else []


func _index_of_node(node: Node3D) -> int:
	for i in range(enemies.size()):
		if enemies[i]["node"] == node:
			return i
	return -1


func _defeat_enemy(index: int) -> void:
	var enemy: Dictionary = enemies[index]
	battle_ui.hide_enemy_hp(index)
	var node = enemy["node"]
	if is_instance_valid(node):
		node.queue_free()
	enemy["node"] = null
	await _wait(MESSAGE_DELAY)


func _check_victory() -> bool:
	for enemy in enemies:
		if enemy["hp"] > 0:
			return false
	_victory()
	return true


func _victory() -> void:
	_busy = true
	battle_ui.hide_attack_menu()
	battle_ui.show_message("Victory!", Color(1.0, 0.85, 0.2))
	var reward := 0
	for enemy in enemies:
		reward += int(enemy["resource"].XPReward)
	GameData.gain_XP(reward)
	if GameData.current_enemy_id != "" and not GameData.defeated_enemies.has(GameData.current_enemy_id):
		GameData.defeated_enemies.append(GameData.current_enemy_id)
	await _wait(1.5)
	get_tree().change_scene_to_file(RETURN_SCENE)


func _defeat() -> void:
	_busy = true
	GameData.player_hp = 0
	battle_ui.refresh_bars(false)
	battle_ui.show_death()


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout
