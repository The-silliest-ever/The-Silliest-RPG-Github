class_name AttackResource
extends Resource

enum AttackCategory { PHYSICAL, SPECIAL, HEAL }

@export_category("Basic Info")
@export var name: String = "Enrique"
@export var sprite_texture: Texture2D
@export var type: AttackCategory = AttackCategory.PHYSICAL
@export var unlocked: bool = false

@export_category("Base Output")
@export_range(0, 99999) var damage: int = 10
@export_range(0, 999) var heal_amount: int = 0
@export_range(0,99,1) var miss_chance: int = 0

@export_category("Stat Changes (Target)")
@export var buffs_target: Array[Resource] = [] # Typed as Resource to prevent scope/loading order errors
@export var debuffs_target: Array[Resource] = []

@export_category("Stat Changes (Self)")
@export var buffs_self: Array[Resource] = []
@export var debuffs_self: Array[Resource] = []

@export_category("Status Effects")
@export var target_statuses: Array[Resource] = []
@export var self_statuses: Array[Resource] = []

# --- HELPER FUNCTIONS ---
func applies_target_status() -> bool:
	return target_statuses.size() > 0
	
func applies_self_status() -> bool:
	return self_statuses.size() > 0

func unlock():
	unlocked = true
