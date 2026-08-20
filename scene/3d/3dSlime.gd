extends CharacterBody3D

@export var speed: float = 3.0
var player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	# FIX 1: Look for the capitalized "Player" group
	var players = get_tree().get_nodes_in_group("Player")
	
	if players.size() > 0:
		player = players[0]
	else:
		# FIX 2: Fallback path using your exact "3dPlayer" node name
		player = get_node_or_null("../3dPlayer")

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Safety check in case it still cannot find the node
	if player == null:
		move_and_slide()
		return

	# Calculate path to 3dPlayer
	var current_pos = global_position
	var target_pos = player.global_position
	var direction = target_pos - current_pos
	direction.y = 0 # Prevent the slime from tilting up/down
	
	# Move if not already touching the player
	if direction.length() > 0.5:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()

	# Rotate smoothly to look at the player
	if direction.length_squared() > 0.01:
		var look_target = Vector3(target_pos.x, current_pos.y, target_pos.z)
		look_at(look_target, Vector3.UP)
