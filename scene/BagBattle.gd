extends Panel

@onready var bag = %BagMenu

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
	
	# Connect Attack Menu Signals
	
	# Hide the detail panel initially
	detail_panel.visible = false
	
	refresh_menu()

func show_menu(menu_to_show: Control):
	# 1. Hide all menus
	bag.visible = false
	
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
