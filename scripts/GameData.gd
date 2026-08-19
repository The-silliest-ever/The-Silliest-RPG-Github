extends Node

#Signals
signal inventory_updated
signal item_picked_up(item: Item)
signal party_updated

#enemy stuff
@export var current_enemy_id = ""
@export var defeated_enemies = []
@export var enemy_type = "Enrique"
var current_enemy: EnemyResource
var current_enemy_hp: int

#player stuff
@export var player_hp = 30 # Changed starting HP to match Max HP
var player_maxHP = 30
@export var strength = 5
@export var defense = 1
@export var sillyTokens = 0

var playerPos: Vector2 = Vector2.ZERO

var inventory: Array[Item] = []

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

# Active Party
var active_party: Array[PartyMember] = [
	preload("res://Party Members/Player.tres"),
	null
]

var reserve_party: Array[PartyMember] = [
	preload("res://Party Members/Floppa.tres")
]

#item addition
func add_item(new_item: Item) -> void:
	inventory.append(new_item)
	print("Picked up: " + new_item.Name)
	
	inventory_updated.emit()
	
	# Broadcast what was picked up for itemGot
	item_picked_up.emit(new_item)
