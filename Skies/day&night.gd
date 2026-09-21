extends Node3D

@onready var anim_player = $AnimationPlayer

@export_group("Weather Nodes")
@export var weather_anim_player: AnimationPlayer
@export var rain_particles: GPUParticles3D

@export_group("Animation Names")
@export var rain_start_anim: String = "rain_start"
@export var rain_stop_anim: String = "rain_stop"
@export var raining_loop_anim: String = "raining_loop"

@export_group("Weather Controls")
@export_range(0.0, 1.0) var rain_chance: float = 0.35  # 35% chance to rain
@export_range(0.0, 1.0) var rain_check_time: float = 0.3  # Time of day to check (e.g., 0.3 = Afternoon)

var weathercheckkk: bool = false


func _ready() -> void:
	anim_player.play("day_night_cycle")
	# Instantly seek animation to the persistent timestamp
	anim_player.seek(GameData.day_cycle_time, true)
	
	if rain_particles:
		rain_particles.emitting = false
		
func _process(_delta: float) -> void:
	# Keep GameData updated with current playback position
	if anim_player.is_playing():
		GameData.day_cycle_time = anim_player.current_animation_position
		
	# Keep rain particles centered over active camera
	var camera = get_viewport().get_camera_3d()
	if camera and rain_particles:
		rain_particles.global_position = camera.global_position + Vector3(0, 10, 0)
	var current_time = GameData.day_cycle_time
	
	# 1. Reset the check flag when a new day starts (e.g. past midnight / 0.0)
	if current_time < 0.1:
		weathercheckkk = false
		
	# 2. Check for rain once when crossing the target time
	if current_time >= rain_check_time and not weathercheckkk:
		weathercheckkk = true
		_roll_for_rain()


var is_raining: bool = false

## Call this function from any script or event to trigger rain
func start_rain() -> void:
	if is_raining or not weather_anim_player:
		return
		
	is_raining = true
	weather_anim_player.play(rain_start_anim)
	
	# Queue the optional loop animation if provided
	if weather_anim_player.has_animation(raining_loop_anim):
		weather_anim_player.queue(raining_loop_anim)

## Call this function to clear the sky
func stop_rain() -> void:
	if not is_raining or not weather_anim_player:
		return
		
	is_raining = false
	weather_anim_player.play(rain_stop_anim)

## Helper to toggle weather on/off
func toggle_rain() -> void:
	if is_raining:
		stop_rain()
	else:
		start_rain()

func rain_for_lilbit(duration: float = 30.0) -> void:
	start_rain()
	await get_tree().create_timer(duration).timeout
	stop_rain()

func _roll_for_rain() -> void:
	# randf() generates a random float between 0.0 and 1.0
	var roll = randf()
	
	if roll <= rain_chance:
		print("Weather roll (", roll, " <= ", rain_chance, ")! Today I'm feelin... IT'S RAININNNNNNNNNNN")
		rain_for_lilbit(480)
	else:
		print("Weather roll (", roll, " > ", rain_chance, "). Today I'm feelin... clear skies babyyyy")
