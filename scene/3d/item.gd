@tool
extends Area3D

@export var item_resource: Item:
	set(value):
		item_resource = value
		_update_visuals()

## Desired on-screen size of the item in world units (its longest edge).
## The Sprite3D's pixel_size is derived from this, so the item looks the same
## size no matter how many pixels the source texture has.
@export var world_size: float = 0.5:
	set(value):
		world_size = value
		_update_visuals()

@onready var sprite: Sprite3D = $Sprite3D

func _ready() -> void:
	_update_visuals()
	
	# Only connect the signal during gameplay, not inside the editor
	if not Engine.is_editor_hint():
		if not body_entered.is_connected(_on_body_entered):
			body_entered.connect(_on_body_entered)

func _update_visuals() -> void:
	if not is_node_ready():
		return
		
	if item_resource and item_resource.icon:
		sprite.texture = item_resource.icon
		_fit_sprite_to_texture()
	else:
		sprite.texture = null

## Scales the sprite so its longest edge is `world_size` units,
## independent of the texture's pixel resolution.
func _fit_sprite_to_texture() -> void:
	var tex_size: Vector2 = sprite.texture.get_size()
	var longest_edge: float = maxf(tex_size.x, tex_size.y)
	if longest_edge > 0.0:
		sprite.pixel_size = world_size / longest_edge

func _on_body_entered(body: Node3D) -> void:
	if Engine.is_editor_hint():
		return
	
	# Adjust this check based on how your player node is named or grouped
	if body.name == "Player" or body.is_in_group("Player"):
		if item_resource:
			GameData.add_item(item_resource) # Adds item to inventory and emits signals[cite: 5]
			queue_free() # Removes the item from the world
