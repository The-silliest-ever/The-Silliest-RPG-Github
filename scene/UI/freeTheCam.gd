extends Button

func _ready():
	# Connects the button's built-in pressed signal to our custom function
	pressed.connect(_on_pressed)

func _on_pressed():
	GameData.toggle_freecam.emit()
