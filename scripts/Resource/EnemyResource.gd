class_name EnemyResource
extends Resource

# --- Info ---
@export_category("Basic Information")
@export var Name: String = "Enemy Name"
@export var Sprite: Texture2D
@export_range(1, 100, 1) var level: int = 1

# --- Rewards ---
@export_category("Rewards")
@export_range(0, 10000, 1) var XPReward: int = 20
@export_range(0, 10000, 1) var MoneyReward: int = 5

# --- Stats ---
@export_category("Stats")
@export_range(1, 9999, 1) var MaxHP: int = 30
@export_range(1, 1000, 1) var Physical_stat: float = 20.0
@export_range(1, 1000, 1) var Special_stat: float = 20.0

@export_group("Defenses")
@export_range(1, 1000, 1) var Defense_stat: float = 20.0
@export_range(1, 1000, 1) var Special_Defense_stat: float = 20.0

@export_group("Combat Utilities")
@export_range(1, 1000, 1) var Speed_stat: float = 20.0
@export_range(0.0, 100.0, 0.1) var dodge_chance: float = 5.0 # Lowered default to 5% so attacks don't miss constantly!

# --- Attacks ---
@export_category("AI & Moveset")
@export var attacks: Array[AttackResource] = []
