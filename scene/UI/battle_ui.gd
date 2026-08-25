extends Control

# The UI defines the signal, but doesn't handle the combat math
signal action_selected(action_type, target)

@onready var member_label = $Player
@onready var second_member = $SecondParty

@onready var attack_container = $AttackContainer # Adjust to your exact node path

func Make_attack_menu(current_member: PartyMember):
	# 1. Clear out any old buttons from the previous turn
	for child in attack_container.get_children():
		child.queue_free()
		
	# 2. Safety check: prevent crashes if the party slot is null
	if current_member == null:
		return
		
	# 3. Loop through the 4 equipped attacks
	for attack in current_member.equipped_attacks:
		# Safety check: skip this specific slot if no attack is equipped
		if attack == null:
			continue
			
		var btn = Button.new()
		btn.text = attack.name
		
		# Connect the button so it knows which attack it represents
		btn.pressed.connect(func(): _on_attack_button_pressed(attack))
		
		attack_container.add_child(btn)

func _on_attack_button_pressed(chosen_attack: AttackResource):
	print("Player selected: ", chosen_attack.name)
	# Here, you would emit a signal UP to the Battle System with the chosen_attack
	
# The Battle System will call this function directly
func update_member_display(member_name: String):
	member_label.text = member_name 
