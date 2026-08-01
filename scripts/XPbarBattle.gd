extends ProgressBar

@onready var LevelCounter = %Label

# Call this from external scripts to handle the math and animation together
func add_xp_animated(amount: int):
	var old_max_xp = max_value
	
	# Let your backend handle the logic
	GameData.gain_XP(amount)
	
	# Update label instantly or handle it post-tween
	LevelCounter.text = str(GameData.level)
	
	var tween = create_tween()
	if old_max_xp != GameData.MaxXP:
		# Level up animation sequence
		tween.tween_property(self, "value", old_max_xp, 0.25).set_trans(Tween.TRANS_SINE)
		tween.tween_property(self, "value", 0.0, 0.0)
		tween.tween_callback(func(): max_value = GameData.MaxXP)
		tween.tween_property(self, "value", GameData.experience, 0.25).set_trans(Tween.TRANS_SINE)
	else:
		# Standard animation
		tween.tween_property(self, "value", GameData.experience, 0.5).set_trans(Tween.TRANS_SINE)
		
	# Return the tween so the battle system knows when it finishes
	return tween
