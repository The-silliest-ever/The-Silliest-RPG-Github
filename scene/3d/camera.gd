extends Camera3D

@export var fly_speed: float = 10.0
@export var mouse_sensitivity: float = 0.005

var is_freecam: bool = false
var default_position: Vector3
var default_rotation: Vector3

func _ready():
	# Save the original local position and rotation relative to the player
	default_position = position
	default_rotation = rotation
	
	# Listen for the UI button press
	GameData.toggle_freecam.connect(_on_toggle_freecam)

func _on_toggle_freecam():
	is_freecam = !is_freecam
	
	# top_level detaches the camera from the player's movement constraints
	top_level = is_freecam 
	
	if not is_freecam:
		# Snap back to the original offset tracking the player
		position = default_position
		rotation = default_rotation

func _unhandled_input(event):
	if not is_freecam: return
	
	# Hold Right-Click to pan the camera around
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotation.y -= event.relative.x * mouse_sensitivity
		rotation.x -= event.relative.y * mouse_sensitivity
		# Clamp the vertical rotation to prevent the camera from flipping upside down
		rotation.x = clamp(rotation.x, -PI/2, PI/2)

func _process(delta):
	if not is_freecam: return
	
	# Move using standard WASD / Arrow Keys
	var input_dir = Input.get_vector("freecamleft", "freecamright", "freecamUp", "freecamdown")
	
	# Calculate movement direction relative to where the camera is currently looking
	var move_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	if move_dir:
		position += move_dir * fly_speed * delta
