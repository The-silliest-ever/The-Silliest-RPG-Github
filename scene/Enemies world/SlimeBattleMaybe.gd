class_name OverworldEnemy
extends Area2D

# Drag your specific .tres resource here in the Inspector
@export var enemy_resource: EnemyResource 

# Unique identifier so the game knows WHICH enemy was defeated
@export var enemy_id: String = ""

func _ready():
	# If no manual ID was set in the inspector, auto-generate one based on node path
	if enemy_id == "":
		enemy_id = str(get_path())

	# Check if this specific enemy was already defeated previously
	if GameData.defeated_enemies.has(enemy_id):
		queue_free() # Remove from overworld on load

func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		trigger_encounter()

func trigger_encounter():
	# Pass both the resource AND the unique ID to GameData
	GameData.current_enemy = enemy_resource
	GameData.current_enemy_hp = enemy_resource.MaxHP
	GameData.current_enemy_id = enemy_id
	
	# Transition to battle
	get_tree().call_deferred("change_scene_to_file", "res://scene/Battle.tscn")
