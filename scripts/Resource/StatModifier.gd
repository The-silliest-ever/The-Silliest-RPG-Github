class_name StatModifier
extends Resource

enum StatType { NONE, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE }

@export var stat: StatType = StatType.ATTACK
@export_range(1, 6, 1) var stages: int = 1
