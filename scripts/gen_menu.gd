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

func _ready():
	show_menu(bag)
	
	# Connect directly to the GameData Autoload's signal
	GameData.inventory_updated.connect(refresh_menu)
	
	# Connect our UI signals for the detail panel
	item_list.item_selected.connect(_on_item_selected)
	use_button.pressed.connect(_on_use_pressed)
	
	# Hide the detail panel initially
	detail_panel.visible = false
	
	# Populate the menu immediately
	refresh_menu()

func show_menu(menu_to_show: Control):
	# 1. Hide all menus
	bag.visible = false
	party.visible = false
	attacks.visible = false
	settings.visible = false
	
	# 2. Show the specific menu passed into the function
	menu_to_show.visible = true

func refresh_menu() -> void:
	item_list.clear()
	
	# Loop through the Autoload's inventory array
	for item in GameData.inventory:
		item_list.add_item(item.Name, item.icon, true)
		
	# Hide the detail panel when the list refreshes so we don't look at old data
	detail_panel.visible = false

# --- Detail Panel Logic ---

func _on_item_selected(index: int) -> void:
	selected_index = index
	var clicked_item = GameData.inventory[index]
	
	# Populate the UI with the item's data
	item_name.text = clicked_item.Name 
	item_desc.text = clicked_item.description
	item_icon.texture = clicked_item.icon
	
	# Dynamically update the extra info label
	if clicked_item.heal_percentage > 0:
		extra_info_label.text = "Heals " + str(clicked_item.heal_percentage) + "% HP"
	else:
		extra_info_label.text = "No additional effects."
	
	# Only show the Use button if it can actually be consumed
	use_button.visible = clicked_item.is_consumable
	
	# Reveal the panel
	detail_panel.visible = true

func _on_use_pressed() -> void:
	if selected_index == -1:
		return
		
	var item = GameData.inventory[selected_index]
	
	# Call the item's use function
	item.use_item()
	
	# Remove the consumed item from the GameData array
	GameData.inventory.remove_at(selected_index)
	
	# Tell GameData to broadcast that the inventory changed
	GameData.inventory_updated.emit()

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

func _onSettingsPressed() -> void:
	show_menu(settings)
