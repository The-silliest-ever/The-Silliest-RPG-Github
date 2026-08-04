extends Node

#References

#enemy stuff
@export var current_enemy_id = ""
@export var defeated_enemies = []
@export var enemy_type = "Enrique"
var current_enemy: EnemyResource
var current_enemy_hp: int

#player stuff
@export var player_hp = 20
@export var player_maxHP = 30
@export var strength = 5
@export var defense = 1
@export var money = 0

var playerPos: Vector2 = Vector2.ZERO

#Leveling stuff
@export var level = 1
@export var experience = 0
@export var MaxXP = get_requiered_XP(level + 1)

#functions

# Changed "level" to "target_level" here to prevent shadowing
func get_requiered_XP(target_level):
	return round(pow(target_level, 1.8) + target_level * 4)

func level_up():
	level += 1
	MaxXP = get_requiered_XP(level + 1)
	GlobalCalls.levelup.emit()

func gain_XP(amount):
	experience += amount
	while experience >= MaxXP:
		experience -= MaxXP
		level_up()

# Preload your attack resources or load them as needed
var unlocked_attacks: Array[AttackResource] = []

# Holds the 4 equipped moves for battle
var equipped_attacks: Array[AttackResource] = [
	preload("res://AttackResources/Slash.tres"),
	preload("res://AttackResources/Fireball.tres"),
	preload("res://AttackResources/Punch.tres"),
	preload("res://AttackResources/HealingSpell.tres")
]
