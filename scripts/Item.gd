extends Area2D

@export var ItemData: Item

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	
	$TextureRect.texture = ItemData.icon
	
	
func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		GameData.add_item(ItemData)
		queue_free()
		print("Player has picked up an item from the world and it might be a ", ItemData.Name)
	else:
		print("Bruh that literally isn't even the player")
