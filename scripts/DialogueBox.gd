extends CanvasLayer

signal choice_selected(index: int)

@onready var text_label: RichTextLabel = $MarginContainer/Box/text
@onready var icon_rect: TextureRect = $MarginContainer/Box/Icon
@onready var options: Array[Button] = [%Option1, %Option2, %Option3]

var tween: Tween
var current_choices: Array[String] = [] # Declared here to store choices globally

@export var seconds_per_character: float = 0.03

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	for i in range(options.size()):
		var callable = _on_option_pressed.bind(i)
		if not options[i].pressed.is_connected(callable):
			options[i].pressed.connect(callable)
	
	hide()

func display_dialogue(dialogue_text: String, speaker_icon: Texture2D = null, choices: Array[String] = []) -> void:
	get_tree().paused = true
	current_choices = choices # Save choices for _show_choices()
	
	# Reset choices
	for opt in options:
		opt.hide()

	if speaker_icon:
		icon_rect.texture = speaker_icon
		icon_rect.show()
	else:
		icon_rect.hide()

	text_label.text = dialogue_text
	text_label.visible_characters = 0
	show()

	# Typewriter Animation
	if tween and tween.is_running():
		tween.kill()
		
	tween = create_tween()
	var duration = dialogue_text.length() * seconds_per_character
	tween.tween_property(text_label, "visible_characters", dialogue_text.length(), duration)
	
	await tween.finished
	_show_choices()

func _input(event: InputEvent) -> void:
	# Optional: Click/Accept to skip typewriter effect and reveal choices immediately
	if visible and event.is_action_pressed("ui_accept"):
		if tween and tween.is_running():
			tween.kill()
			text_label.visible_characters = text_label.text.length()
			_show_choices()

func _show_choices() -> void:
	for i in range(options.size()):
		if i < current_choices.size():
			options[i].text = current_choices[i]
			options[i].show()
			options[i].disabled = false

func _on_option_pressed(index: int) -> void:
	hide()
	get_tree().paused = false
	choice_selected.emit(index)
