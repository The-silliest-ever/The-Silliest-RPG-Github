extends Area2D

@export var npc_sprite: Texture2D

func _input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		print("SUCCESS: CLICKED IN WORLD SPACE!")
		
		var choices: Array[String] = ["Whaataaaaataattatataatatt??????", "Not yet.", "Who are you?"]
		TextBox.display_dialogue("Your mother!!", npc_sprite, choices)
		
		var chosen_option = await TextBox.choice_selected
		if chosen_option == 0:
			print("Player picked Option 1")
