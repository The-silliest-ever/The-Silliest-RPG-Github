extends ProgressBar

@onready var LevelCounter = %Label
@onready var XPbar = %XP

func _ready() -> void:
	# Initialize the UI layout on startup
	max_value = GameData.MaxXP
	value = GameData.experience
	LevelCounter.text = str(GameData.level)
	
	GlobalCalls.levelup.connect(leveled_up)

func _input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_accept"): 
		return
		
	# 1. Store the OLD max XP before calculating new gains
	var old_max_xp = max_value
	
	# 2. Add the experience points
	GameData.gain_XP(50)
	
	# 3. Update the text label immediately
	LevelCounter.text = str(GameData.level)
	
	# Debug print statements
	print("player's current XP is ", GameData.experience)
	print("player's maxXP is ", GameData.MaxXP)
	
	# 4. Trigger the appropriate visual animation
	# Check if the player's level changed during gain_XP
	if max_value != GameData.MaxXP:
		animate_level_up(old_max_xp, GameData.MaxXP, GameData.experience)
	else:
		animate_normal_gain(GameData.experience)

# Visual function for normal XP gain (no level up)
func animate_normal_gain(target_xp: float, duration: float = 0.5):
	var tween = create_tween()
	tween.tween_property(self, "value", target_xp, duration).set_trans(Tween.TRANS_SINE)

# Visual function for leveling up
func animate_level_up(old_max: float, new_max: float, target_xp: float, duration: float = 0.5):
	var tween = create_tween()
	
	# 1. Fill the bar completely based on the previous level's maximum
	tween.tween_property(self, "value", old_max, duration * 0.5).set_trans(Tween.TRANS_SINE)
	
	# 2. Instantly jump back to zero and swap out the max_value to the new level's limit
	tween.tween_property(self, "value", 0.0, 0.0)
	tween.tween_callback(func(): max_value = new_max)
	
	# 3. Fill the remaining progress up to the current XP amount
	tween.tween_property(self, "value", target_xp, duration * 0.5).set_trans(Tween.TRANS_SINE)

# Keeps your global signal listener intact just in case other nodes trigger it
func leveled_up():
	pass 
