extends ProgressBar

@export var animate_duration: float = 0.35
var _tween: Tween

## This is the function you will call from other scripts
func update_bar(new_value: float) -> void:
	if _tween and _tween.is_running():
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "value", new_value, animate_duration)\
		.set_trans(Tween.TRANS_SINE)\
		.set_ease(Tween.EASE_OUT)
