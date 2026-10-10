extends CharacterBody3D

@export var speed: float = 3.0
var Player: Node3D = null
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

@export var enemy_resource: EnemyResource
@export var enemy_id: String = ""

var seePlayer: bool = false

func _ready() -> void:
	print("I am spawn - Slime")
	var Players = get_tree().get_nodes_in_group("Player")
	if Players.size() > 0:
		Player = Players[0]
	else:
		Player = get_node_or_null("../3dPlayer")
		
	if enemy_id == "":
		enemy_id = str(get_path())
		
	if GameData.defeated_enemies.has(enemy_id):
		queue_free()

func _physics_process(delta: float) -> void:
	# Apply gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
		
	if Player == null:
		print("there IS no Player muhahaha - Slime")
		move_and_slide()
		return

	if seePlayer:
		print("I see youu - Slime")
		var current_pos = global_position
		var target_pos = Player.global_position
		var direction = target_pos - current_pos
		direction.y = 0

		if direction.length() > 0.5:
			direction = direction.normalized()
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0
			velocity.z = 0

		if direction.length_squared() > 0.01:
			var look_target = Vector3(target_pos.x, current_pos.y, target_pos.z)
			if not global_position.is_equal_approx(look_target):
				look_at(look_target, Vector3.UP)
	else:
		velocity.x = 0
		velocity.z = 0

	# Ensure move_and_slide runs every frame so gravity applies
	move_and_slide()

func _on_player_touch(body: Node3D):
	if body.is_in_group("Player"):
		print("grr im angry time to take it out on this nerd - Slime")
		trigger_encounter()

func trigger_encounter():
	GameData.current_enemy = enemy_resource
	GameData.current_enemy_hp = enemy_resource.MaxHp
	GameData.current_enemy_id = enemy_id
	get_tree().call_deferred("change_scene_to_file", "res://scene/3d/3dBattle.tscn")

func _on_notice_player(body: Node3D) -> void:
	if body.is_in_group("Player"):
		seePlayer = true

func _on_notice_player_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		seePlayer = false
