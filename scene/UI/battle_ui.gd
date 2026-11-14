class_name BattleUI
extends Control

## Emitted when the player has chosen an attack AND a target enemy.
signal action_selected(attack_resource: AttackResource, target: Node3D)

@onready var member_label: Label = $Player
@onready var second_member_label: Label = $SecondParty
@onready var turn_label: Label = %Turns
@onready var attack_container: HBoxContainer = %AttackContainer

@onready var enemy_hp_bar_1: ProgressBar = $Enemy1hp
@onready var enemy_hp_label_1: Label = $Enemy1hp/whoisyou
@onready var enemy_hp_bar_2: ProgressBar = $Enemy2hp
@onready var enemy_hp_label_2: Label = $Enemy2hp/whoisyou2

var active_enemies: Array = []
var pending_attack: AttackResource = null
## Maps a spawned target Button -> { "enemy": Node3D, "anchor": Node3D }.
var target_buttons: Dictionary = {}


func _ready() -> void:
	enemy_hp_bar_1.hide()
	enemy_hp_bar_2.hide()
	attack_container.hide()
	refresh_bars(false)


# ------------------------------------------------------------------ setup
func setup_battle(enemies_in_battle: Array, member: PartyMember) -> void:
	active_enemies = enemies_in_battle
	member_label.text = member.name if member != null else "Empty"
	var second: PartyMember = GameData.active_party[1] if GameData.active_party.size() > 1 else null
	second_member_label.text = second.name if second != null else ""
	build_attack_menu(member)
	refresh_bars(false)


func build_attack_menu(member: PartyMember) -> void:
	_clear(attack_container.get_children())
	if member == null:
		return
	for attack in member.equipped_attacks:
		if attack == null:
			continue
		var button := Button.new()
		button.text = attack.name
		button.pressed.connect(_on_attack_pressed.bind(attack))
		attack_container.add_child(button)


func show_attack_menu() -> void:
	attack_container.show()


func hide_attack_menu() -> void:
	attack_container.hide()


# ------------------------------------------------------------------ messages
func show_message(text: String, color: Color = Color.WHITE) -> void:
	turn_label.text = text
	turn_label.add_theme_color_override("font_color", color)


# ------------------------------------------------------------------ bars
func refresh_bars(animate: bool = true) -> void:
	_set_bar(%PlayerHealth, GameData.player_hp, GameData.player_maxHP, animate)
	%HealthShow.text = "%d / %d" % [int(round(GameData.player_hp)), int(round(GameData.player_maxHP))]
	_set_bar(%"2ndPartyHealth2", GameData.partymemembrHP, GameData.partmembrMaxHP, animate)


func update_enemy_hp(index: int, current_hp: int, max_hp: int, enemy_name: String, animate: bool = true) -> void:
	var bar: ProgressBar
	var label: Label
	match index:
		0:
			bar = enemy_hp_bar_1
			label = enemy_hp_label_1
		1:
			bar = enemy_hp_bar_2
			label = enemy_hp_label_2
		_:
			return
	bar.max_value = max_hp
	label.text = enemy_name
	bar.show()
	if animate:
		bar.update_bar(current_hp)
	else:
		bar.value = current_hp


func hide_enemy_hp(index: int) -> void:
	match index:
		0:
			enemy_hp_bar_1.hide()
		1:
			enemy_hp_bar_2.hide()


func _set_bar(bar: ProgressBar, value: float, max_value: float, animate: bool) -> void:
	bar.max_value = max_value
	if animate and bar.has_method("update_bar"):
		bar.update_bar(value)
	else:
		bar.value = value


# ------------------------------------------------------------------ statuses
func update_status_icons(player_statuses: Array, enemy_statuses: Array) -> void:
	_apply_status_row([%playerBurn, %playerPoison, %playerGroovy], player_statuses)
	_apply_status_row([%burn, %poison, %groovy], enemy_statuses)


func _apply_status_row(icons: Array, statuses: Array) -> void:
	var active := [
		StatusEffectData.StatusType.BURN,
		StatusEffectData.StatusType.POISON,
		StatusEffectData.StatusType.GROOVY,
	]
	var present := {}
	for type in active:
		present[type] = false
	for status in statuses:
		if present.has(status["type"]):
			present[status["type"]] = true
	for i in range(active.size()):
		icons[i].visible = present[active[i]]


# ------------------------------------------------------------------ targeting
func _on_attack_pressed(attack: AttackResource) -> void:
	pending_attack = attack
	attack_container.hide()
	_spawn_target_buttons()


func _spawn_target_buttons() -> void:
	_clear_target_buttons()
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			continue
		var button := Button.new()
		button.text = "Target"
		button.pressed.connect(_on_target_pressed.bind(enemy))
		add_child(button)
		# Cache the anchor once instead of re-resolving it every frame.
		target_buttons[button] = {"enemy": enemy, "anchor": enemy.get_node_or_null("TargetAnchor")}


func _process(_delta: float) -> void:
	if target_buttons.is_empty():
		return
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return
	for button in target_buttons:
		var info: Dictionary = target_buttons[button]
		var anchor: Node3D = info["anchor"]
		if is_instance_valid(anchor):
			button.position = camera.unproject_position(anchor.global_position)


func _on_target_pressed(enemy: Node3D) -> void:
	_clear_target_buttons()
	var attack := pending_attack
	pending_attack = null
	if attack != null:
		action_selected.emit(attack, enemy)


func _clear_target_buttons() -> void:
	for button in target_buttons:
		if is_instance_valid(button):
			button.queue_free()
	target_buttons.clear()


# ------------------------------------------------------------------ death
func show_death() -> void:
	$DeathScreen.fade_in()
	await get_tree().create_timer(3.0).timeout
	get_tree().quit()


func _clear(nodes: Array) -> void:
	for node in nodes:
		node.queue_free()
