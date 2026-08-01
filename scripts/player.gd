extends CharacterBody2D

@onready var LevelCounter = %Label
@onready var XPbar = %XP

func _ready() -> void:
	XPbar.value = GameData.experience
	XPbar.max_value = GameData.MaxXP
	LevelCounter.text = str(GameData.level)
	
	if GameData.playerPos != Vector2.ZERO:
		global_position = GameData.playerPos

func _physics_process(_delta):
	var direction = Input.get_vector("move_left","move_right","move_up","move_down")
	velocity = direction * 600
	move_and_slide()
	
	# This constantly saves your position to the Autoload.
	# When the slime changes the scene, this stops running, 
	# leaving GameData.playerPos frozen at your exact encounter spot!
	GameData.playerPos = global_position
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation()
	else:
		%HappyBoo.play_idle_animation()
