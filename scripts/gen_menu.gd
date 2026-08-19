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
# Attack Menu Navigation Nodes
@onready var member_label: Label = %Member
@onready var arrow_forward: Button = %ArrowForward
@onready var arrow_backward: Button = %ArrowBackward

var current_member_index: int = 0

# UI for selecting the attack
@onready var attack_selection_panel: Panel = %AttackSelectionPanel 
@onready var unlocked_attacks_list: ItemList = %UnlockedAttacksList

# Keep track of which slot (0, 1, 2, or 3) the player is trying to change
var slot_to_change: int = -1

var regex = RegEx.create_from_string("[A-Za-z].*[A-Za-z]")


#-------Party Menu -----------
@onready var member1_name: Label = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member1
@onready var member2_name: Label = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member2
@onready var member1_img: TextureRect = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member1Image
@onready var member2_img: TextureRect = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member2Image
@onready var member1_desc: RichTextLabel = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member1desc
@onready var member2_desc: RichTextLabel = $Control/PanelContainer/BG/MarginContainer/PartyMenu/Member2desc

@onready var btn_switch1: Button = $Control/PanelContainer/BG/MarginContainer/PartyMenu/SwitchMember1
@onready var btn_switch2: Button = $Control/PanelContainer/BG/MarginContainer/PartyMenu/SwitchMember2

@onready var party_selection_panel: Panel = %PartySelectionPanel
@onready var reserve_member_list: ItemList = %ReserveMemberList

var party_slot_to_change: int = -1

var active_party: Array[PartyMember] = [
	preload("res://Party Members/Player.tres"), # Loads Player.tres as default for Member 1
	null                                        # Leave Member 2 empty by default
]

var reserve_party: Array[PartyMember] = []
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
	btn_switch1.pressed.connect(_on_switch_slot_pressed.bind(0))
	btn_switch2.pressed.connect(_on_switch_slot_pressed.bind(1))
	GameData.party_updated.connect(refresh_party_menu)
	# Hide the detail panel initially
	detail_panel.visible = false
	# Connect Switch buttons
	btn_switch1.pressed.connect(_on_switch_slot_pressed.bind(0))
	btn_switch2.pressed.connect(_on_switch_slot_pressed.bind(1))
	
	reserve_member_list.item_selected.connect(_on_reserve_member_selected)
	party_selection_panel.visible = false
	
	# Populate the menus immediately
	refresh_menu()
	refresh_attack_menu()
	refresh_party_menu()
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
	
	# Checks if the string exists and contains more than 1 letter
	if clicked_item.OtherInfo and regex.search(clicked_item.OtherInfo) != null:
		extra_info_label.text = clicked_item.OtherInfo
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

func _on_arrow_forward_pressed() -> void:
	if current_member_index < GameData.active_party.size() - 1:
		current_member_index += 1
		refresh_attack_menu()

func _on_arrow_backward_pressed() -> void:
	if current_member_index > 0:
		current_member_index -= 1
		refresh_attack_menu()

func refresh_attack_menu() -> void:
	# 1. Toggle arrow visibility based on current page
	arrow_backward.visible = (current_member_index > 0)
	arrow_forward.visible = (current_member_index < GameData.active_party.size() - 1)
	
	# 2. Safety check for empty/missing party slot
	if current_member_index >= GameData.active_party.size() or GameData.active_party[current_member_index] == null:
		member_label.text = "Empty Slot"
		var attack_buttons = [btn_attack1, btn_attack2, btn_attack3, btn_attack4]
		for btn in attack_buttons:
			btn.text = "Empty Slot"
		return

	# 3. Load active character details
	var current_member = GameData.active_party[current_member_index]
	member_label.text = current_member.name
	
	# 4. Populate their equipped moves
	var attack_buttons = [btn_attack1, btn_attack2, btn_attack3, btn_attack4]
	for i in range(4):
		if i < current_member.equipped_attacks.size() and current_member.equipped_attacks[i] != null:
			attack_buttons[i].text = current_member.equipped_attacks[i].name
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
	var selected_attack = unlocked_attacks_list.get_item_metadata(index)
	
	if current_member_index < GameData.active_party.size():
		var current_member = GameData.active_party[current_member_index]
		if current_member != null:
			current_member.equipped_attacks[slot_to_change] = selected_attack
	
	refresh_attack_menu()
	attack_selection_panel.visible = false
	slot_to_change = -1
	
#---------Party Menu Functions-------
func refresh_party_menu() -> void:
	print("--- REFRESHING PARTY MENU ---")
	print("GameData.active_party array: ", GameData.active_party)

	var names = [member1_name, member2_name]
	var images = [member1_img, member2_img]
	var descs = [member1_desc, member2_desc]

	for i in range(2):
		if i < GameData.active_party.size() and GameData.active_party[i] != null:
			var member = GameData.active_party[i]
			print("Slot ", i, " contains: ", member.name)
			names[i].text = member.name
			images[i].texture = member.portrait
			descs[i].text = member.description
		else:
			print("Slot ", i, " is EMPTY")
			names[i].text = "Empty Slot"
			images[i].texture = null
			descs[i].text = "No member assigned."

# --- Switching Logic ---

func _on_switch_slot_pressed(slot_index: int) -> void:
	party_slot_to_change = slot_index
	reserve_member_list.clear()
	
	# 1. Add current reserve members to list
	for member in GameData.reserve_party:
		if member != null:
			var idx = reserve_member_list.add_item(member.name, member.portrait)
			reserve_member_list.set_item_metadata(idx, member)
			
	# 2. Add an option to unequip/leave slot empty
	var empty_idx = reserve_member_list.add_item("[ Empty Slot ]")
	reserve_member_list.set_item_metadata(empty_idx, null)

	party_selection_panel.visible = true

func _on_reserve_member_selected(index: int) -> void:
	var selected_member: PartyMember = reserve_member_list.get_item_metadata(index)
	var other_slot = 1 if party_slot_to_change == 0 else 0
	var current_member = GameData.active_party[party_slot_to_change]

	# Handle Swapping if the selected member is already in the other active slot
	if selected_member != null and GameData.active_party[other_slot] == selected_member:
		GameData.active_party[other_slot] = current_member
	else:
		# If replacing an active member with a reserve member, return old member to reserves
		if current_member != null and not GameData.reserve_party.has(current_member):
			GameData.reserve_party.append(current_member)
		
		# Remove new active member from reserves so they aren't duplicated
		if selected_member != null:
			GameData.reserve_party.erase(selected_member)

	# Assign to active party slot
	GameData.active_party[party_slot_to_change] = selected_member

	# Refresh UI & close popup
	refresh_party_menu()
	party_selection_panel.visible = false
	party_slot_to_change = -1

# --- Navigation Button Callbacks ---

func _on_exit_pressed() -> void:
	get_tree().paused = false
	queue_free()

func _onBagPressed() -> void:
	show_menu(bag)

func _onPartyPressed() -> void:
	show_menu(party)
	refresh_party_menu()
	
func _onAttacksPressed() -> void:
	current_member_index = 0
	show_menu(attacks)
	refresh_attack_menu()

func _onSettingsPressed() -> void:
	show_menu(settings)
