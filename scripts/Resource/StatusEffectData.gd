class_name StatusEffectData
extends Resource

enum StatusType { NONE, BURN, POISON, GROOVY, LIFESTEAL, MINI, ELECTRIFIED }

@export var type: StatusType = StatusType.BURN
@export_range(1, 10, 1) var duration: int = 3
@export_range(0, 100, 1) var value: int = 0
