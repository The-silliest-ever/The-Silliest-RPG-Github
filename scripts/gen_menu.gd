extends CanvasLayer

@onready var bag = $Control/PanelContainer/BG/MarginContainer/BagMenu
@onready var party = $Control/PanelContainer/BG/MarginContainer/PartyMenu
@onready var attacks = $Control/PanelContainer/BG/MarginContainer/AttackMenu
@onready var settings = $Control/PanelContainer/BG/MarginContainer/SettingsMenu

# --- Bag / Inventory Nodes ---
@onready var item_list: ItemList = %ItemList

# Detail Panel Nodes
@onready var detail_panel: Panel = %Panel
@onready var item_icon: TextureRect = %TextureRect
@onready var item_name: Label = %ItemName
@onready var item_desc: RichTextLabel = %ItemDescription
@onready var use_button: Button = %"Equip or use"
@onready var extra_info_label: Label = %"Info goes here"

# Keep track of which item index is clicked
var selected_index: int = -1

# --- Attack Menu Nodes ---
@onready var btn_attack1: Button = %attack1 
@onready var btn_attack2: Button = %attack2
@onready var btn_attack3: Button = %attack3
@onready var btn_attack4: Button = %attack4

# UI for selecting the attack
@onready var attack_selection_panel: Panel = %AttackSelectionPanel 
@onready var unlocked_attacks_list: ItemList = %UnlockedAttacksList

# Keep track of which slot (0, 1, 2, or 3) the player is trying to change
var slot_to_change: int = -1

func _ready():
	show_menu(bag)
	
	# Connect directly to the GameData Autoload's signal
	GameData.inventory_updated.connect(refresh_menu)
	
	# Connect our UI signals for the detail panel
	item_list.item_selected.connect(_on_item_selected)
	use_button.pressed.connect(_on_use_pressed)
	
	# Connect Attack Menu Signals
	btn_attack1.pressed.connect(_on_attack_slot_pressed.bind(0))
	btn_attack2.pressed.connect(_on_attack_slot_pressed.bind(1))
	btn_attack3.pressed.connect(_on_attack_slot_pressed.bind(2))
	btn_attack4.pressed.connect(_on_attack_slot_pressed.bind(3))
	
	unlocked_attacks_list.item_selected.connect(_on_new_attack_selected)
	attack_selection_panel.visible = false
	
	# Hide the detail panel initially
	detail_panel.visible = false
	
	# Populate the menus immediately
	refresh_menu()
	refresh_attack_menu()

func show_menu(menu_to_show: Control):
	# 1. Hide all menus
	bag.visible = false
	party.visible = false
	attacks.visible = false
	settings.visible = false
	
	# Hide popup panels just in case
	attack_selection_panel.visible = false
	
	# 2. Show the specific menu passed into the function
	menu_to_show.visible = true

func refresh_menu() -> void:
	item_list.clear()
	
	for item in GameData.inventory:
		item_list.add_item("", item.icon, true)
		
	detail_panel.visible = false

# --- Detail Panel Logic ---

func _on_item_selected(index: int) -> void:
	selected_index = index
	var clicked_item = GameData.inventory[index]
	
	item_name.text = clicked_item.Name 
	item_desc.text = clicked_item.description
	item_icon.texture = clicked_item.icon
	
	if clicked_item.heal_percentage > 0:
		extra_info_label.text = "Heals " + str(clicked_item.heal_percentage) + "% HP"
	else:
		extra_info_label.text = "No additional effects."
	
	use_button.visible = clicked_item.is_consumable
	detail_panel.visible = true

func _on_use_pressed() -> void:
	if selected_index == -1:
		return
		
	var item = GameData.inventory[selected_index]
	item.use_item()
	GameData.inventory.remove_at(selected_index)
	GameData.inventory_updated.emit()


# --- Attack Menu Logic ---

func refresh_attack_menu() -> void:
	# Group the buttons into an array so we can easily loop through them
	var attack_buttons = [btn_attack1, btn_attack2, btn_attack3, btn_attack4]
	
	for i in range(4):
		# Check if the Autoload array has a slot here, and if it's not null
		if i < GameData.equipped_attacks.size() and GameData.equipped_attacks[i] != null:
			var attack = GameData.equipped_attacks[i]
			
			# Using lowercase 'name' to match your AttackResource
			attack_buttons[i].text = attack.name 
		else:
			attack_buttons[i].text = "Empty Slot"

func _on_attack_slot_pressed(slot_index: int) -> void:
	slot_to_change = slot_index
	unlocked_attacks_list.clear()
	
	# Open the directory where your attacks are stored
	var dir = DirAccess.open("res://AttackResources")
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		# Loop through all files in the folder
		while file_name != "":
			if not dir.current_is_dir():
				# Remove .remap so this works in exported builds
				var clean_file_name = file_name.replace(".remap", "")
				
				# Check if the file is a Godot resource file
				if clean_file_name.ends_with(".tres") or clean_file_name.ends_with(".res"):
					var res_path = "res://AttackResources/" + clean_file_name
					var attack = load(res_path) as AttackResource
					
					# Make sure it loaded successfully AND is unlocked
					if attack and attack.unlocked == true:
						var item_index = unlocked_attacks_list.add_item(attack.name)
						
						# Save the attack data into the list item's metadata
						unlocked_attacks_list.set_item_metadata(item_index, attack)
						
			# Move to the next file
			file_name = dir.get_next()
			
	# Show the prompt to choose an attack
	attack_selection_panel.visible = true

func _on_new_attack_selected(index: int) -> void:
	# Get the attack data we stored in the metadata earlier
	var selected_attack = unlocked_attacks_list.get_item_metadata(index)
	
	# Ensure the equipped_attacks array is large enough before assigning
	while GameData.equipped_attacks.size() <= slot_to_change:
		GameData.equipped_attacks.append(null)
	
	# Update the Autoload
	GameData.equipped_attacks[slot_to_change] = selected_attack
	
	# Refresh the 4 buttons to show the new attack
	refresh_attack_menu()
	
	# Hide the selection panel
	attack_selection_panel.visible = false
	slot_to_change = -1


# --- Navigation Button Callbacks ---

func _on_exit_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _onBagPressed() -> void:
	show_menu(bag)

func _onPartyPressed() -> void:
	show_menu(party)

func _onAttacksPressed() -> void:
	show_menu(attacks)
	refresh_attack_menu() 

func _onSettingsPressed() -> void:
	show_menu(settings)
