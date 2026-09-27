extends Node3D

@export var enemy_scene: PackedScene = preload("res://scene/3d/3dSlime.tscn")

# 1. Set the maximum number of spawns
const MAX_SPAWNS: int = 3
var total_spawned: int = 0

@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout() -> void:
	# 2. Check if we have already hit our maximum limit
	if total_spawned >= MAX_SPAWNS:
		timer.stop() # Stop the timer entirely since we are done spawning
		return
		
	spawn_enemy()

func spawn_enemy() -> void:
	if not enemy_scene:
		return
	
	# 3. Increment the counter
	total_spawned += 1
	
	var enemy = enemy_scene.instantiate()
	
	var random_offset = Vector3(randf_range(-5.0, 5.0), 0, randf_range(-5.0, 5.0))
	get_tree().current_scene.add_child(enemy)
	enemy.global_position = global_position + random_offset
