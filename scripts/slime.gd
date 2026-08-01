extends CharacterBody2D

@onready var player = get_node("/root/Main/Player")

func _ready():
	if %Area2D.enemy_id == "":
		%Area2D.enemy_id = str(get_path())
		print("Slime Id: ", %Area2D.enemy_id)
	%Slime.play_walk()
	if GameData.defeated_enemies.has(%Area2D.enemy_id):
		queue_free()
		return

func _physics_process(_delta):
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * 200.0
	move_and_slide()
