extends CharacterBody3D

@export var speed: float = 3.0
var Player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

# Drag your specific .tres resource here in the Inspector
@export var enemy_resource: EnemyResource 

# Unique identifier so the game knows WHICH enemy was defeated
@export var enemy_id: String = ""

func _ready() -> void:
	print("I seee yoooouu - Slime")
	var Players = get_tree().get_nodes_in_group("Player")
	
	if Players.size() > 0:
		Player = Players[0]
	else:
		# FIX 2: Fallback path using your exact "3dPlayer" node name
		Player = get_node_or_null("../3dPlayer")
		
		# If no manual ID was set in the inspector, auto-generate one based on node path
	if enemy_id == "":
		enemy_id = str(get_path())

	# Check if this specific enemy was already defeated previously
	if GameData.defeated_enemies.has(enemy_id):
		queue_free() # Remove from overworld on load

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0

	# Safety check in case it still cannot find the node
	if Player == null:
		print("there IS no Player muhahaha - Slime")
		move_and_slide()
		return

	# Calculate path to 3dPlayer
	var current_pos = global_position
	var target_pos = Player.global_position
	var direction = target_pos - current_pos
	direction.y = 0 # Prevent the slime from tilting up/down
	
	# Move if not already touching the Player
	if direction.length() > 0.5:
		direction = direction.normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = 0
		velocity.z = 0
		
	move_and_slide()

	# Rotate smoothly to look at the Player
	if direction.length_squared() > 0.01:
			var look_target = Vector3(target_pos.x, current_pos.y, target_pos.z)
			# Ensure we aren't trying to look exactly at ourselves
			if not global_position.is_equal_approx(look_target):
				look_at(look_target, Vector3.UP)

func _on_player_touch(body: Node3D):
	if body.is_in_group("Player"):
		print("grr im angry time to take it out on this nerd - Slime")
		trigger_encounter()

func trigger_encounter():
	# Pass both the resource AND the unique ID to GameData
	GameData.current_enemy = enemy_resource
	GameData.current_enemy_hp = enemy_resource.MaxHP
	GameData.current_enemy_id = enemy_id
	
	# Transition to battle
	get_tree().call_deferred("change_scene_to_file", "res://scene/3d/3dBattle.tscn")
