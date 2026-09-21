extends Node3D

@onready var anim_player = $AnimationPlayer

func _ready() -> void:
	anim_player.play("day_night_cycle")
	# Instantly seek animation to the persistent timestamp
	anim_player.seek(GameData.day_cycle_time, true)

func _process(_delta: float) -> void:
	# Keep GameData updated with current playback position
	if anim_player.is_playing():
		GameData.day_cycle_time = anim_player.current_animation_position
