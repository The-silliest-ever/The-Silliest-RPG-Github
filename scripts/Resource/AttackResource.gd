class_name AttackResource
extends Resource

# --- ENUMS ---
enum AttackCategory { PHYSICAL, SPECIAL, HEAL }
enum StatType { NONE, ATTACK, DEFENSE, SPECIAL_ATTACK, SPECIAL_DEFENSE }
enum StatusType { NONE, BURN, POISON, GROOVY, LIFESTEAL, MINI, ELECTRIFIED }

@export_category("Info")
@export var name: String = "Enrique"
@export var sprite_texture: Texture2D
@export var type: AttackCategory = AttackCategory.PHYSICAL

@export_category("Output")
@export_range(0, 999) var damage: int = 10
@export_range(0, 999) var heal_amount: int = 0

@export_category("Stat Changes")
@export_group("Affecting Target")
@export var statAdd: StatType = StatType.NONE
@export var statMinus: StatType = StatType.NONE

@export_group("Affecting Self")
@export var statAddSelf: StatType = StatType.NONE
@export var statMinusSelf: StatType = StatType.NONE

@export_category("Status Effects")
@export_group("Affecting Target")
@export var target_status: StatusType = StatusType.NONE
@export_range(1, 10) var target_status_duration: int = 3
@export_range(0, 100) var target_status_value: int = 0

@export_group("Affecting Self")
@export var self_status: StatusType = StatusType.NONE
@export_range(1, 10) var self_status_duration: int = 3
@export_range(0, 100) var self_status_value: int = 0

# --- HELPER FUNCTIONS ---

func applies_target_status() -> bool:
	return target_status != StatusType.NONE
	
func applies_self_status() -> bool:
	return self_status != StatusType.NONE
