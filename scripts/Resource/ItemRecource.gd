class_name Item
extends Resource

@export_category("Info")
@export var Name: String = "Item Name Here"
@export var icon: Texture2D
@export_multiline var description: String = "A description of the item DUUUH"

@export_category("Inventory properties")
@export var max_stack_size: int = 99
@export_range(0, 100) var heal_percentage: float = 0.0
@export var sell_value: int = 10
@export var is_consumable: bool = false

func use_item() -> void:
	if not is_consumable:
		return
		
	if heal_percentage > 0.0:
		# Calculate the heal based on GameData stats
		var heal_amount = GameData.player_maxHP * (heal_percentage / 100.0)
		
		# Add it to the current HP and clamp it so it doesn't go over max
		GameData.player_hp += heal_amount
		GameData.player_hp = clamp(GameData.player_hp, 0.0, GameData.player_maxHP)
		
		print("Healed for ", heal_amount, ". Current HP is now: ", GameData.player_hp)
