class_name EnemyResource
extends Resource

@export var Name: String = "Set name"
@export var Sprite: Texture2D
@export var MaxHP: int = 30
@export var XPReward: int = 20

@export var attacks: Array[AttackResource] = []

@export_range(1,1000,1) var Defense_stat: float = 20.0
@export_range(1,1000,1) var Physical_stat: float = 20.0
@export_range(1,1000,1) var Special_stat: float = 20.0
@export_range(1,1000,1) var Speed_stat: float = 20.0
@export_range(1,100,1) var dodge_chance: float = 20.0
