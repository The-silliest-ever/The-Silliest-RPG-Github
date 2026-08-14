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

func use_item_heal(target: Node) -> void:
	if not is_consumable:
		print("This item cannot be consumed.")
		return
		
	if heal_percentage > 0.0:
		
		if "max_health" in target and target.has_method("heal"):
			
			var heal_amount = target.max_health * (heal_percentage / 100.0)
			
			target.heal(heal_amount)
			print(Name + " healed " + target.name + " for " + str(heal_amount) + " HP!")
			
		else:
			print(target.name + " is at full health dumbaah")
		
	print(Name + " was used on " + target.name)

func use_item_weapon(target: Node) -> void:
	if not is_consumable:
		print("bruh")
		return
	
	print(Name + "was equipped")
