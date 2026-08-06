extends Node

#References

#enemy stuff
@export var current_enemy_id = ""
@export var defeated_enemies = []
@export var enemy_type = "Enrique"
var current_enemy: EnemyResource
var current_enemy_hp: int

#player stuff
@export var player_hp = 30 # Changed starting HP to match Max HP
var player_maxHP = 30 # Removed @export because we calculate this dynamically now!
@export var strength = 5
@export var defense = 1
@export var money = 0

var playerPos: Vector2 = Vector2.ZERO

#Leveling stuff
@export var level = 1
@export var experience = 0
var MaxXP = 0

func _ready():
	# When the game runs, calculate everything based on the starting level
	MaxXP = get_requiered_XP(level + 1)
	player_maxHP = calculate_max_hp(level)
	player_hp = player_maxHP

#functions

# hp calc
func calculate_max_hp(target_level: int) -> int:
	# Linear progression: 30 HP at lvl 1 -> 1000 HP at lvl 100
	# 970 is the HP difference, 99 is the level difference.
	var calculated_hp = 30 + round((target_level - 1) * (970.0 / 99.0))
	return int(calculated_hp)

func get_requiered_XP(target_level):
	return round(pow(target_level, 1.8) + target_level * 4)

func level_up():
	level += 1
	MaxXP = get_requiered_XP(level + 1)
	
	# update max hp on lvlup
	var old_max_hp = player_maxHP
	player_maxHP = calculate_max_hp(level)
	

	var hp_gained = player_maxHP - old_max_hp
	player_hp = min(player_hp + hp_gained, player_maxHP)

	
	GlobalCalls.levelup.emit()

func gain_XP(amount):
	experience += amount
	while experience >= MaxXP:
		experience -= MaxXP
		level_up()

# Preload attack resources or load them as needed
var unlocked_attacks: Array[AttackResource] = []

# Holds the 4 equipped moves for battle
var equipped_attacks: Array[AttackResource] = [
	preload("res://AttackResources/Slash.tres"),
	preload("res://AttackResources/Fireball.tres"),
	preload("res://AttackResources/Punch.tres"),
	preload("res://AttackResources/HealingSpell.tres")
]
